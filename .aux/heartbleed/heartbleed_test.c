#ifndef ANGELIX_OUTPUT
#define ANGELIX_OUTPUT(type, expr, id) expr
#endif

/* test/heartbleed_test.c */
/*
 * Unit test for TLS heartbeats.
 *
 * Acts as a regression test against the Heartbleed bug (CVE-2014-0160).
 *
 * Author:  Mike Bland (mbland@acm.org, http://mike-bland.com/)
 * Date:    2014-04-12
 * License: Creative Commons Attribution 4.0 International (CC By 4.0)
 *          http://creativecommons.org/licenses/by/4.0/deed.en_US
 *
 * Converted from Google-style to OpenSSL style and contributed to OpenSSL as
 * heartbeat_test.c:
 *   http://git.openssl.org/gitweb/?p=openssl.git;a=blob;f=ssl/heartbeat_test.c
 *   http://goo.gl/1F7SKs
 *
 * Pull request: https://github.com/openssl/openssl/pull/81
 * Discussion:
 *   https://groups.google.com/d/msg/mailing.openssl.dev/N96KqJ6WgTs/YelyxMJoqmUJ
 *   https://groups.google.com/d/msg/mailing.openssl.dev/k_oL10ysLUo/r93f_hHZBwMJ
 *   https://groups.google.com/d/msg/mailing.openssl.dev/ge4PIs3byZk/Uhp0vLoGlEMJ
 *
 * URL:
 *   https://code.google.com/p/mike-bland/source/browse/heartbleed/heartbleed_test.c
 *   http://goo.gl/w1bGyR
 *
 * BUILDING AND RUNNING
 * --------------------
 * Download the build.sh script if you don't want to do everything by hand:
 *
 * https://code.google.com/p/mike-bland/source/browse/heartbleed/build.sh
 * http://goo.gl/erKNJm
 *
 * Otherwise: As per CVE-2014-0160, download the following tarballs:
 *
 *   The version that introduced the Heartbleed bug:
 *   http://www.openssl.org/source/openssl-1.0.1-beta1.tar.gz
 *
 *   The version that contains the fix for the Heartbleed bug:
 *   http://www.openssl.org/source/openssl-1.0.1g.tar.gz
 *
 * Unpack and run ./config && make for each. Then, add these lines to the
 * bottom of test/Makefile:
 *
 *   heartbleed_test.o: heartbleed_test.c
 *   heartbleed_test: heartbleed_test.o $(DLIBCRYPTO)
 *     @target=heartbleed_test; $(BUILD_CMD)
 *
 * Copy this test file to test/heartbleed_test.c and run:
 *   $ make TESTS=heartbleed_test test
 *   $ test/heartbleed_test
 *
 * OUTPUT
 * ------
 * The program returns zero on success. It will print a message with a count
 * of the number of failed tests and return nonzero if any tests fail.
 *
 * It will print the contents of the request and response buffers for each
 * failing test. In a "fixed" version, all the tests should pass and there
 * should be no output.
 *
 * In a "bleeding" version, you'll see:
 *
 *   TestDtls1Heartbleed failed:
 *     expected payload len: 0
 *     received: 1024
 *   sent 26 characters
 *     "HEARTBLEED                "
 *   received 1024 characters
 *     "HEARTBLEED                \xde\xad\xbe\xef..."
 *   ** TestDtls1Heartbleed failed **
 *
 * The contents of the returned buffer in the failing test will depend on the
 * contents of memory on your machine.
 *
 * PSEUDO-XUNIT STYLE
 * ------------------
 * This test is written in what I call the Pseudo-xUnit style:
 * http://mike-bland.com/2014/06/05/pseudo-xunit-pattern.html
 *
 * MORE INFORMATION
 * ----------------
 * http://mike-bland.com/2014/04/12/heartbleed.html
 * http://mike-bland.com/tags/heartbleed.html
 */

#include "../ssl/ssl_locl.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* As per https://tools.ietf.org/html/rfc6520#section-4 */
const int kMinPaddingSize = 16;

/* Maximum number of payload characters to print as test output */
const int kMaxPrintableCharacters = 1024;

typedef struct {
  SSL_CTX *ctx;
  SSL *s;
  const char* test_case_name;
  int (*process_heartbeat)(SSL* s);
  unsigned char* payload;
  int sent_payload_len;
  int expected_return_value;
  int return_payload_offset;
  int expected_payload_len;
  const char* expected_return_payload;
} HeartbleedTestFixture;

static HeartbleedTestFixture SetUp(const char* const test_case_name,
    const SSL_METHOD* meth) {
  HeartbleedTestFixture fixture;
  int setup_ok = 1;
  memset(&fixture, 0, sizeof(fixture));
  fixture.test_case_name = test_case_name;

  fixture.ctx = SSL_CTX_new(meth);
  if (!fixture.ctx) {
    fprintf(stderr, "Failed to allocate SSL_CTX for test: %s\n",
            test_case_name);
    setup_ok = 0;
    goto fail;
  }

  fixture.s = SSL_new(fixture.ctx);
  if (!fixture.s) {
    fprintf(stderr, "Failed to allocate SSL for test: %s\n", test_case_name);
    setup_ok = 0;
    goto fail;
  }

  if (!ssl_init_wbio_buffer(fixture.s, 1)) {
    fprintf(stderr, "Failed to set up wbio buffer for test: %s\n",
            test_case_name);
    setup_ok = 0;
    goto fail;
  }

  if (!ssl3_setup_buffers(fixture.s)) {
    fprintf(stderr, "Failed to setup buffers for test: %s\n", test_case_name);
    setup_ok = 0;
    goto fail;
  }

  /* Clear the memory for the return buffer, since this isn't automatically
   * zeroed in opt mode and will cause spurious test failures that will change
   * with each execution.
   */
  memset(fixture.s->s3->wbuf.buf, 0, fixture.s->s3->wbuf.len);

fail:
  if (!setup_ok) {
    ERR_print_errors_fp(stderr);
    exit(EXIT_FAILURE);
  }
  return fixture;
}

static HeartbleedTestFixture SetUpDtls(const char* const test_case_name) {
  HeartbleedTestFixture fixture = SetUp(test_case_name,
                                        DTLSv1_server_method());
  fixture.process_heartbeat = dtls1_process_heartbeat;

  /* As per dtls1_get_record(), skipping the following from the beginning of
   * the returned heartbeat message:
   * type-1 byte; version-2 bytes; sequence number-8 bytes; length-2 bytes
   *
   * And then skipping the 1-byte type encoded by process_heartbeat for
   * a total of 14 bytes, at which point we can grab the length and the
   * payload we seek.
   */
  fixture.return_payload_offset = 14;
  return fixture;
}

/* Needed by ssl3_write_bytes() */
static int DummyHandshake(SSL* s) {
  return 1;
}

static HeartbleedTestFixture SetUpTls(const char* const test_case_name) {
  HeartbleedTestFixture fixture = SetUp(test_case_name,
                                        TLSv1_server_method());
  fixture.process_heartbeat = tls1_process_heartbeat;
  fixture.s->handshake_func = DummyHandshake;

  /* As per do_ssl3_write(), skipping the following from the beginning of
   * the returned heartbeat message:
   * type-1 byte; version-2 bytes; length-2 bytes
   *
   * And then skipping the 1-byte type encoded by process_heartbeat for
   * a total of 6 bytes, at which point we can grab the length and the payload
   * we seek.
   */
  fixture.return_payload_offset = 6;
  return fixture;
}

static void TearDown(HeartbleedTestFixture fixture) {
  ERR_print_errors_fp(stderr);
  SSL_free(fixture.s);
  SSL_CTX_free(fixture.ctx);
}

static void PrintPayload(const char* const prefix,
    const unsigned char *payload, const int n) {
  const int end = n < kMaxPrintableCharacters ? n : kMaxPrintableCharacters;
  printf("%s %d character%s", prefix, n, n == 1 ? "" : "s");
  if (end != n) printf(" (first %d shown)", end);
  printf("\n  \"");

  int i = 0;
  for (; i != end; ++i) {
    const unsigned char c = payload[i];
    if (isprint(c)) fputc(c, stdout);
    else printf("\\x%02x", c);
  }
  printf("\"\n");
}

static int ExecuteHeartbeat(HeartbleedTestFixture fixture) {
  int result = 0;
  SSL* s = fixture.s;
  unsigned char *payload = fixture.payload;
  unsigned char sent_buf[kMaxPrintableCharacters + 1];

  s->s3->rrec.data = payload;
  s->s3->rrec.length = strlen((const char*)payload);
  *payload++ = TLS1_HB_REQUEST;
  s2n(fixture.sent_payload_len, payload);

  /* Make a local copy of the request, since it gets overwritten at some
   * point */
  memcpy((char *)sent_buf, (const char*)payload, sizeof(sent_buf));

  int return_value = fixture.process_heartbeat(s);

  ANGELIX_OUTPUT(int, return_value, "return_value");

  if (return_value != fixture.expected_return_value) {
    printf("%s failed: expected return value %d, received %d\n",
           fixture.test_case_name, fixture.expected_return_value,
           return_value);
    result = 1;
  }

  /* If there is any byte alignment, it will be stored in wbuf.offset. */
  unsigned const char *p = &(s->s3->wbuf.buf[
      fixture.return_payload_offset + s->s3->wbuf.offset]);
  int actual_payload_len = 0;
  n2s(p, actual_payload_len);

  ANGELIX_OUTPUT(int, actual_payload_len, "actual_payload_len");

  if (actual_payload_len != fixture.expected_payload_len) {
    printf("%s failed:\n  expected payload len: %d\n  received: %d\n",
           fixture.test_case_name, fixture.expected_payload_len,
           actual_payload_len);
    PrintPayload("sent", sent_buf, strlen((const char*)sent_buf));
    PrintPayload("received", p, actual_payload_len);
    result = 1;
  } else {
    char* actual_payload = strndup((const char*)p, actual_payload_len);
    if (strcmp(actual_payload, fixture.expected_return_payload) != 0) {
      printf("%s failed:\n  expected payload: \"%s\"\n  received: \"%s\"\n",
             fixture.test_case_name, fixture.expected_return_payload,
             actual_payload);
      result = 1;
    }
    free(actual_payload);
  }

  if (result != 0) {
    printf("** %s failed **\n--------\n", fixture.test_case_name);
  }
  TearDown(fixture);
  return result;
}

static int ExecuteHeartbeat2(HeartbleedTestFixture fixture) {
  int result = 0;
  SSL* s = fixture.s;
  unsigned char *payload = fixture.payload;
  unsigned char sent_buf[kMaxPrintableCharacters + 1];

  s->s3->rrec.data = payload;
  s->s3->rrec.length = strlen((const char*)payload);
  *payload++ = TLS1_HB_RESPONSE;
  s2n(fixture.sent_payload_len, payload);

  /* Make a local copy of the request, since it gets overwritten at some
   * point */
  memcpy((char *)sent_buf, (const char*)payload, sizeof(sent_buf));

  int return_value = fixture.process_heartbeat(s);

  ANGELIX_OUTPUT(int, return_value, "return_value");

  if (return_value != fixture.expected_return_value) {
    printf("%s failed: expected return value %d, received %d\n",
           fixture.test_case_name, fixture.expected_return_value,
           return_value);
    result = 1;
  }

  /* If there is any byte alignment, it will be stored in wbuf.offset. */
  unsigned const char *p = &(s->s3->wbuf.buf[
      fixture.return_payload_offset + s->s3->wbuf.offset]);
  int actual_payload_len = 0;
  n2s(p, actual_payload_len);

  ANGELIX_OUTPUT(int, actual_payload_len, "actual_payload_len");

  if (result != 0) {
    printf("** %s failed **\n--------\n", fixture.test_case_name);
  }
  TearDown(fixture);
  return result;
}

static int HonestPayloadSize(unsigned char payload_buf[]) {
  /* Omit three-byte pad at the beginning for type and payload length */
  return strlen((const char*)&payload_buf[3]) - kMinPaddingSize;
}

static int TestDtls1NotBleeding() {
  HeartbleedTestFixture fixture = SetUpDtls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   Not bleeding, sixteen spaces of padding"
          "                ";
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "Not bleeding, sixteen spaces of padding";
  return ExecuteHeartbeat(fixture);
}

static int TestDtls1NotBleedingEmptyPayload() {
  HeartbleedTestFixture fixture = SetUpDtls(__func__);
  /* Three-byte pad at the beginning for type and payload length, plus a NUL
   * at the end */
  unsigned char payload_buf[4 + kMinPaddingSize];
  memset(payload_buf, ' ', sizeof(payload_buf));
  payload_buf[sizeof(payload_buf) - 1] = '\0';
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestDtls1Heartbleed() {
  HeartbleedTestFixture fixture = SetUpDtls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   HEARTBLEED                ";

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = kMaxPrintableCharacters;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestDtls1HeartbleedEmptyPayload() {
  HeartbleedTestFixture fixture = SetUpDtls(__func__);
  /* Excluding the NUL at the end, one byte short of type + payload length +
   * minimum padding */
  unsigned char payload_buf[kMinPaddingSize + 3];
  memset(payload_buf, ' ', sizeof(payload_buf));
  payload_buf[sizeof(payload_buf) - 1] = '\0';

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = kMaxPrintableCharacters;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestDtls1HeartbleedExcessivePlaintextLength() {
  HeartbleedTestFixture fixture = SetUpDtls(__func__);
  /* Excluding the NUL at the end, one byte in excess of maximum allowed
   * heartbeat message length */
  unsigned char payload_buf[SSL3_RT_MAX_PLAIN_LENGTH + 2];
  memset(payload_buf, ' ', sizeof(payload_buf));
  payload_buf[sizeof(payload_buf) - 1] = '\0';

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = HonestPayloadSize(payload_buf);
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1NotBleeding() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   Not bleeding, sixteen spaces of padding"
          "                ";
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "Not bleeding, sixteen spaces of padding";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1NotBleeding2() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   Not bleeding, seventeen spaces of padding"
          "                 ";
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "Not bleeding, seventeen spaces of padding ";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1NotBleeding3() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   Not bleeding  "
          "                ";
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "Not bleeding  ";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1NotBleedingEmptyPayload() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length, plus a NUL
   * at the end */
  unsigned char payload_buf[4 + kMinPaddingSize];
  memset(payload_buf, ' ', sizeof(payload_buf));
  payload_buf[sizeof(payload_buf) - 1] = '\0';
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1Heartbleed() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   HEARTBLEED                ";

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = kMaxPrintableCharacters;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1Heartbleed2() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   HEARTBLEED"
    "                                 ";

  const int payload_buf_len = HonestPayloadSize(payload_buf);
  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len + 1;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1Heartbleed3() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   HEARTBLEED HEARTBLEED, sixteen spaces of padding"
          "                ";

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = kMaxPrintableCharacters;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1HeartbleedCornerCase() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   HEARTBLEED                ";

  const int payload_buf_len = HonestPayloadSize(payload_buf);
  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len + 18;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1HeartbleedEmptyPayload() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Excluding the NUL at the end, one byte short of type + payload length +
   * minimum padding */
  unsigned char payload_buf[kMinPaddingSize + 3];
  memset(payload_buf, ' ', sizeof(payload_buf));
  payload_buf[sizeof(payload_buf) - 1] = '\0';

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = kMaxPrintableCharacters;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = 0;
  fixture.expected_return_payload = "";
  return ExecuteHeartbeat(fixture);
}

static int TestTls1HeartbleedResponse() {
  HeartbleedTestFixture fixture = SetUpTls(__func__);
  /* Three-byte pad at the beginning for type and payload length */
  unsigned char payload_buf[] = "   Not bleeding, sixteen spaces of padding"
          "                ";
  const int payload_buf_len = HonestPayloadSize(payload_buf);

  fixture.payload = &payload_buf[0];
  fixture.sent_payload_len = payload_buf_len;
  fixture.expected_return_value = 0;
  fixture.expected_payload_len = payload_buf_len;
  fixture.expected_return_payload = "Not bleeding, sixteen spaces of padding";
  return ExecuteHeartbeat2(fixture);
}


int main(int argc, char *argv[]) {
  SSL_library_init();
  SSL_load_error_strings();

  int id = atoi(argv[1]);

  switch (id) {
    case 1: {
      printf("Test TestTls1NotBleeding ...\n");
      return TestTls1NotBleeding();
    }
    case 2: {
      printf("Test TestTls1NotBleedingEmptyPayload ...\n");
      return TestTls1NotBleedingEmptyPayload();
    }
    case 3: {
      printf("Test TestTls1Heartbleed ...\n");
      return TestTls1Heartbleed();
    }
    case 4: {
      printf("Test TestTls1Heartbleed2 ...\n");
      return TestTls1Heartbleed2();
    }
    case 5: {
      printf("Test TestTls1HeartbleedEmptyPayload ...\n");
      return TestTls1HeartbleedEmptyPayload();
    }
    case 6: {
      printf("Test TestTls1NotBleeding2 ...\n");
      return TestTls1NotBleeding2();
    }
    case 7: {
      printf("Test TestTls1HeartbleedResponse ...\n");
      return TestTls1HeartbleedResponse();
    }
    case 8: {
      printf("Test TestTls1Heartbleed3 ...\n");
      return TestTls1Heartbleed3();
    }
    default:
      printf("Unrecognized test id: %d\n", atoi(argv[1]));
      return 1;
  }


  /* int num_failed = TestDtls1NotBleeding() + */
  /*     TestDtls1NotBleedingEmptyPayload() + */
  /*     TestDtls1Heartbleed() + */
  /*     TestDtls1HeartbleedEmptyPayload() + */
  /*     /\* The following test causes an assertion failure at */
  /*      * ssl/d1_pkt.c:dtls1_write_bytes() in versions prior to 1.0.1g: *\/ */
  /*     (OPENSSL_VERSION_NUMBER >= 0x1000107fL ? */
  /*          TestDtls1HeartbleedExcessivePlaintextLength() : 0) + */
  /*     TestTls1NotBleeding() + */
  /*     TestTls1NotBleedingEmptyPayload() + */
  /*     TestTls1Heartbleed() + */
  /*     TestTls1HeartbleedEmptyPayload() + */
  /*     0; */

  /* ERR_print_errors_fp(stderr); */

  /* if (num_failed != 0) { */
  /*   printf("%d test%s failed\n", num_failed, num_failed != 1 ? "s" : ""); */
  /*   return EXIT_FAILURE; */
  /* } */
  /* return EXIT_SUCCESS; */
}
