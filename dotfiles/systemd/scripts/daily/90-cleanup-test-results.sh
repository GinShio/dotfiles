#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh
if [ -z {{@@ testing.result_dir @@}} ]
then TEST_RESULT_DIR={{@@ testing.baseline_dir @@}}
else TEST_RESULT_DIR={{@@ testing.result_dir @@}}
fi

find $TEST_RESULT_DIR -type f -regextype posix-extended -regex ".*\.tar\.zst$" -mtime +360 -delete
find {{@@ testing.baseline_dir @@}} -type f -regextype posix-extended -regex ".*results\.csv$" -mtime +16 -exec bash -c 'rm -rf $(dirname {})' \;
