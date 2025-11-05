#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh

DATA_REGEXP='[1-9][0-9]{3}-(0[1-9]|1[0-2])-([1-2][0-9]|0[1-9]|3[0-1])'
declare -A DEVICE_VENDORS
DEVICE_VENDORS=(
  [llpc]=$AMDVLK_ICD_PATH
  [mesa]=$RADV_ICD_PATH
  [swrast]=$LVP_ICD_PATH
)

if [ -z {{@@ testing.result_dir @@}} ]
then TEST_RESULT_DIR={{@@ testing.baseline_dir @@}}
else TEST_RESULT_DIR={{@@ testing.result_dir @@}}
fi

for DV in ${!DEVICE_VENDORS[@]}; do
    if [[ ! -e $TEST_RESULT_DIR || ! -e $TEST_RESULT_DIR/$DV ]]; then
        continue
    fi
    GPU_DEVICE_ID=$(VK_ICD_FILENAMES=${DEVICE_VENDORS[$DV]} LD_LIBRARY_PATH=$MESA_ROOT vulkaninfo 2>/dev/null |awk '/deviceID[[:blank:]]*=/ {print $NF; exit}')
    find $TEST_RESULT_DIR/$DV -maxdepth 1 -type f -regextype posix-extended -regex ".*${GPU_TESTKIT_REGEXP}_${GPU_DEVICE_ID}_${DATA_REGEXP}\.tar\.zst" -mtime -10 -print | \
        xargs -I@ bash -c "
            NAME=\$(basename -- @ .tar.zst |awk -F_ -vVENDOR=$DV '{print VENDOR\"_\"\$1\"_\"\$3}');
            mkdir -p {{@@ testing.baseline_dir @@}}/\$NAME && tar --zstd -xf @ -C \$_;
        "
done

fish -c 'copy-graphics-testcase --deqp --piglit --tool'
