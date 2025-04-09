#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh
if [ -z $TEST_RESULT_DIR ]
then TEST_RESULT_DIR=$XDG_RUNTIME_DIR/runner/baseline
fi
TEST_RESULT_DIR=$(eval echo $TEST_RESULT_DIR)

fd -iHx /usr/bin/rm {} \; --regex "\.tar\.zst$" --changed-before 12month -- $TEST_RESULT_DIR
fd -iHx /usr/bin/rm -rf {} \; --changed-before 16d --type directory -- . "$XDG_RUNTIME_DIR/runner/baseline"
