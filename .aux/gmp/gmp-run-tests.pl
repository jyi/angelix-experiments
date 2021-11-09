#!/usr/bin/perl -w
use strict;
use File::Basename;
use Cwd qw();
my @tests = (
    "tests/t-bswap",
    "tests/t-constants",
    "tests/t-count_zeros",
    "tests/t-gmpmax",
    "tests/t-hightomask",
    "tests/t-modlinv",
    "tests/t-popc",
    "tests/t-parity",
    "tests/t-sub",
    "tests/mpz/t-addsub",
    "tests/mpz/t-cmp",
    "tests/mpz/t-mul",
    "tests/mpz/t-mul_i",
    "tests/mpz/t-tdiv",
    "tests/mpz/t-tdiv_ui",
    "tests/mpz/t-fdiv",
    "tests/mpz/t-fdiv_ui",
    "tests/mpz/t-cdiv_ui",
    "tests/mpz/t-gcd-1",
    "tests/mpz/t-gcd_ui",
    "tests/mpz/t-lcm",
    "tests/mpz/dive",
    "tests/mpz/dive_ui",
    "tests/mpz/t-sqrtrem",
    "tests/mpz/convert",
    "tests/mpz/io",
    "tests/mpz/t-inp_str",
    "tests/mpz/logic",
    "tests/mpz/bit",
    "tests/mpz/t-powm",
    "tests/mpz/t-powm_ui",
    "tests/mpz/t-pow",
    "tests/mpz/t-div_2exp",
    "tests/mpz/reuse",
    "tests/mpz/t-root",
    "tests/mpz/t-perfsqr",
    "tests/mpz/t-perfpow",
    "tests/mpz/t-jac",
    "tests/mpz/t-bin",
    "tests/mpz/t-get_d",
    "tests/mpz/t-get_d_2exp",
    "tests/mpz/t-get_si",
    "tests/mpz/t-set_d",
    "tests/mpz/t-set_si",
    "tests/mpz/t-fac_ui",
    "tests/mpz/t-fib_ui",
    "tests/mpz/t-lucnum_ui",
    "tests/mpz/t-scan",
    "tests/mpz/t-fits",
    "tests/mpz/t-divis",
    "tests/mpz/t-divis_2ecounter",
    "tests/mpz/t-cong",
    "tests/mpz/t-cong_2exp",
    "tests/mpz/t-sizeinbase",
    "tests/mpz/t-set_str",
    "tests/mpz/t-aorsmul",
    "tests/mpz/t-cmp_d",
    "tests/mpz/t-cmp_si",
    "tests/mpz/t-hamdist",
    "tests/mpz/t-oddeven",
    "tests/mpz/t-popcount",
    "tests/mpz/t-set_f",
    "tests/mpz/t-io_raw",
    "tests/mpz/t-import",
    "tests/mpz/t-export",
    "tests/mpz/t-pprime_p",
    "tests/mpz/t-nextprime",
    "tests/mpf/t-add",
    "tests/mpf/t-sub",
    "tests/mpf/t-conv",
    "tests/mpf/t-sqrt",
    "tests/mpf/t-sqrt_ui",
    "tests/mpf/t-muldiv",
    "tests/mpf/t-dm2exp",
    "tests/mpf/reuse",
    "tests/mpf/t-cmp_d",
    "tests/mpf/t-cmp_si",
    "tests/mpf/t-div",
    "tests/mpf/t-fits",
    "tests/mpf/t-get_d",
    "tests/mpf/t-get_d_2exp",
    "tests/mpf/t-get_si",
    "tests/mpf/t-get_ui",
    "tests/mpf/t-gsprec",
    "tests/mpf/t-inp_str",
    "tests/mpf/t-int_p",
    "tests/mpf/t-mul_ui",
    "tests/mpf/t-set",
    "tests/mpf/t-set_q",
    "tests/mpf/t-set_si",
    "tests/mpf/t-set_ui",
    "tests/mpf/t-trunc",
    "tests/mpf/t-ui_div",
    "tests/mpf/t-eq",
    "tests/misc/t-printf",
    "tests/misc/t-scanf",
    "tests/misc/t-locale",
    "tests/mpq/t-aors",
    "tests/mpq/t-cmp",
    "tests/mpq/t-cmp_ui",
    "tests/mpq/t-cmp_si",
    "tests/mpq/t-equal",
    "tests/mpq/t-get_d",
    "tests/mpq/t-get_str",
    "tests/mpq/t-inp_str",
    "tests/mpq/t-md_2exp",
    "tests/mpq/t-set_f",
    "tests/mpq/t-set_str",
    "tests/rand/t-iset",
    "tests/rand/t-lc2exp",
    "tests/rand/t-mt",
    "tests/rand/t-rand",
    "tests/rand/t-urbui",
    "tests/rand/t-urmui",
    "tests/rand/t-urndmm",
    "tests/mpn/t-asmtype",
    "tests/mpn/t-aors_1",
    "tests/mpn/t-divrem_1",
    "tests/mpn/t-mod_1",
    "tests/mpn/t-fat",
    "tests/mpn/t-get_d",
    "tests/mpn/t-instrument",
    "tests/mpn/t-iord_u",
    "tests/mpn/t-mp_bases",
    "tests/mpn/t-perfsqr",
    "tests/mpn/t-scan",
    "tests/mpn/t-toom22",
    "tests/mpn/t-toom32",
    "tests/mpn/t-toom33",
    "tests/mpn/t-toom42",
    "tests/mpn/t-toom43",
    "tests/mpn/t-toom44",
    "tests/mpn/t-toom52",
    "tests/mpn/t-toom53",
    "tests/mpn/t-toom62",
    "tests/mpn/t-toom63",
    "tests/mpn/t-toom6h",
    "tests/mpn/t-toom8h",
    "tests/mpn/t-hgcd",
    "tests/mpn/t-matrix22",
    "tests/mpn/t-mullo",
    "tests/mpn/t-mulmod_bnm1",
    "tests/mpn/t-sqrmod_bnm1",
    "tests/mpn/t-invert",
    "tests/mpn/t-div",
    "tests/mpn/t-bdiv",
    #"tests/cxx/t-assign",
    #"tests/cxx/t-binary",
    #"tests/cxx/t-cast",
    #"tests/cxx/t-constr",
    #"tests/cxx/t-headers",
    #"tests/cxx/t-istream",
    #"tests/cxx/t-locale",
    #"tests/cxx/t-misc",
    #"tests/cxx/t-mix",
    #"tests/cxx/t-ops",
    #"tests/cxx/t-ops2",
    #"tests/cxx/t-ops3",
    #"tests/cxx/t-ostream",
    #"tests/cxx/t-prec",
    #"tests/cxx/t-rand",
    #"tests/cxx/t-ternary",
    #"tests/cxx/t-unary"
    );


if (length($ARGV[0]) == 0)
{
    die "Must specify a test number";
}
my $length = scalar @tests;
if ($ARGV[0] =~ m/length/) { print $length; exit 0; }

my $num = $ARGV[0] - 1;
my $selection = $tests[$num];
my $name = basename($selection);
my $dirn =  dirname($selection);



if ($num < 0 || $num > $length)
{
    die "Invalid test number: $num";
}

my $angelix_header = $ENV{'ANGELIX_RUNTIME_H'};

printf "[gmp-run-tests.pl] test number: $num\n";
printf "[gmp-run-tests.pl] test name: $name\n";


my $run = sprintf("\$ANGELIX_RUN");
my $work_dir = basename(Cwd::cwd());
chdir $dirn;
my $cmd;
my $cost_cmd;
if ($num == 19 - 1) {
    $cmd = sprintf("k=%s && rm -f \$k \$k.o test_out && env CC=\"angelix-compiler --klee\" make -e \$k && $run ./\$k > test_out", $name);
    $cost_cmd=sprintf("python3 /angelix-experiments/.aux/gmp/cost-gen.py test_out %s.exp.out", $name);
} else {
    $cmd = sprintf("k=%s && rm -f \$k \$k.o && env CC=\"angelix-compiler --klee\" make -e \$k && $run ./\$k", $name);
    $cost_cmd = "echo \$ANGELIX_DEFAULT_NON_ZERO_COST > \$ANGELIX_COST_FILE";
}

my $test_dir = basename(Cwd::cwd());
print "[gmp-run-tests.pl] test_dir: $work_dir\n";
print "[gmp-run-tests.pl] cmd: $cmd\n";
print "[gmp-run-tests.pl] cost_cmd: $cost_cmd\n";
my @args = ("bash", "-c", "$cmd");
my $result = system(@args);
print "[gmp-run-tests.pl] result: $result\n";

if (defined $ENV{'ANGELIX_COST_FILE'}) {
    system("rm -f \$ANGELIX_COST_FILE");
}

if ($result == 0) {
    if ($num == 19 - 1) {
        my $cmd2 = sprintf("grep -a -v \"WARNING: this target does not support the llvm.stacksave intrinsic.\" test_out && diff test_out %s.exp.out", $name);
        my $result2 = system($cmd2);
        if ($result2 == 0) {
            print "PASS: $name\n";
            my $cost = system($cost_cmd);
            print "[gmp-run-tests.pl] cost: $cost\n";
            exit 0;
        } else {
            print "FAIL: $name\n";
            my $cost = system($cost_cmd);
            print "[gmp-run-tests.pl] cost: $cost\n";
            exit 1;
        }
    } else {
        print "PASS: $name\n";
        my $cost = system($cost_cmd);
        print "[gmp-run-tests.pl] cost: $cost\n";
        exit 0;
    }
} elsif ($result == 35584 || $result == 139) {
    print "SEGFAULT: $name\n";
    print "FAIL: $name\n";
    if (defined $ENV{'ANGELIX_COST_FILE'} && defined $ENV{'ANGELIX_ERROR_COST'} && defined $ENV{'ANGELIX_DEFAULT_NON_ZERO_COST'}) {
        system("echo \$ANGELIX_ERROR_COST + \$ANGELIX_DEFAULT_NON_ZERO_COST | bc > \$ANGELIX_COST_FILE");
    }
    exit $result;
} else {
    print "FAIL: $name\n";
    my $cost = system($cost_cmd);
    print "[gmp-run-tests.pl] cost: $cost\n";
    exit 1;
}
