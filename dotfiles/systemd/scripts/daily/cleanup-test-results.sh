#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh
if [ -z $TEST_RESULT_DIR ]
then TEST_RESULT_DIR=$XDG_RUNTIME_DIR/runner/baseline
fi
TEST_RESULT_DIR=$(eval echo $TEST_RESULT_DIR)

find $TEST_RESULT_DIR -type f -regextype posix-extended -regex ".*\.tar\.zst$" -mtime +360 -delete
find $XDG_RUNTIME_DIR/runner/baseline -type f -regextype posix-extended -regex ".*results\.csv$" -mtime +16 -exec bash -c 'rm -rf $(dirname {})' \;
