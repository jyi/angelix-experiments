#!/bin/sh
#
# Basic sanity check for tiffcp + tiffsplit
#
# First we use tiffcp to join our test files into a multi-frame TIFF
# and then we use tiffsplit to split them out again.
#
. ${srcdir:-.}/common.sh
conjoined=o-tiffcp-split-conjoined.tif
splitfile=o-tiffcp-split-split-
count_file="count"

export MEMCHECK=${ANGELIX_RUN:-eval}; f_test_convert "${TIFFCP}" "${IMG_UNCOMPRESSED}" "${conjoined}"; unset MEMCHECK
if [ ! -f $count_file ]; then
    echo 1 > $count_file
fi
IFS= read FILE_ID < $count_file
conjoined_w_id=o-tiffcp-split-conjoined-${FILE_ID}.tif
cp ${conjoined} ${conjoined_w_id}
echo $(($FILE_ID+1)) > $count_file
# f_test_convert "${TIFFSPLIT}" "${conjoined}" "${splitfile}"
