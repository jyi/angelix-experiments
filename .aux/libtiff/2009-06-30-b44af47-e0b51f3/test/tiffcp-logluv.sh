#!/bin/sh
#
# Basic sanity check for tiffcp with logluv compression
#
. ${srcdir:-.}/common.sh
f_test_convert "${TIFFCP} -c none" "${srcdir}/images/logluv-3c-16b.tiff" "o-tiffcp-logluv-raw.tiff"
export MEMCHECK=${ANGELIX_RUN:-eval}; f_test_convert "${TIFFCP} -c sgilog" "o-tiffcp-logluv-raw.tiff" "o-tiffcp-logluv-sgilog.tiff"; unset MEMCHECK
