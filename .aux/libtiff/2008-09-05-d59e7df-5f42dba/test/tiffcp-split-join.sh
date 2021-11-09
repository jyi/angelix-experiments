#!/bin/sh
#
# Basic sanity check for tiffcp + tiffsplit + tiffcp
#
# First we use tiffcp to join our test files into a multi-frame TIFF
# then we use tiffsplit to split them out again, and then we use
# tiffcp to recombine again.

. ${srcdir:-.}/common.sh
conjoined=o-tiffcp-split-join-conjoined.tif
reconjoined=o-tiffcp-split-join-reconjoined.tif
splitfile=o-tiffcp-split-join-split-

f_test_convert "${TIFFCP}" "${IMG_UNCOMPRESSED}" "${conjoined}"
export MEMCHECK=${ANGELIX_RUN:-eval}; f_test_convert "${TIFFSPLIT}" "${conjoined}" "${splitfile}"; unset MEMCHECK
f_test_convert "${TIFFCP}" "${splitfile}*" "${reconjoined}"
