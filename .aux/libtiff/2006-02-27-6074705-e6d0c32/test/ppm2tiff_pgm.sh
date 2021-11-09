#!/bin/sh
# Generated file, master is Makefile.am
. ${srcdir:-.}/common.sh
infile="$IMG_MINISBLACK_1C_8B_PGM"
outfile="o-ppm2tiff_pgm.tiff"
export MEMCHECK=${ANGELIX_RUN:-eval}; f_test_convert "$PPM2TIFF" $infile $outfile; unset MEMCHECK
f_tiffinfo_validate $outfile
