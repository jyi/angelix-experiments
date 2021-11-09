#!/bin/sh
# Generated file, master is Makefile.am
. ${srcdir:-.}/common.sh
infile="$srcdir/images/logluv-3c-16b.tiff"
outfile="o-tiffcrop-extractz14-logluv-3c-16b.tiff"
# f_test_convert "$TIFFCROP -E left -Z1:4,2:4" $infile $outfile
if ! [ -f ../input/$outfile ]; then
    echo "File does not exist: ../input/$outfile"
    exit 1
fi
cp ../$outfile $outfile
export MEMCHECK=${ANGELIX_RUN:-eval}; f_tiffinfo_validate $outfile; unset MEMCHECK
