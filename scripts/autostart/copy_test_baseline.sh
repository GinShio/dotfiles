#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh

DEVICE_REGEXP='0x[0-9a-fA-F]{4}'
DATA_REGEXP='[1-9][0-9][0-9]{3}-(0[1-9]|1[0-2])-([1-2][0-9]|0[1-9]|3[0-1])'
TESTKIT_REGEXP='((piglit|deqp)-(vk|gl|zink))'
DEVICE_ID=$(vulkaninfo 2>/dev/null |awk '/deviceID[[:blank:]]*=/ {print $NF; exit}')

TEST_RESULT_DIR=$(eval echo $TEST_RESULT_DIR)
if ! [ -z $TEST_RESULT_DIR ]; then
    DEVICE_VENDORS=(llpc mesa)
    for DV in ${DEVICE_VENDORS[@]}; do
        if ! [ -e $TEST_RESULT_DIR ] || ! [ -e $TEST_RESULT_DIR/$DV ]; then
            continue
        fi
        fd -iHx /usr/bin/echo {} \; --regex "${TESTKIT_REGEXP}_${DEVICE_ID}_${DATA_REGEXP}.tar.zst" --changed-withid 8d -- $TEST_RESULT_DIR/$DV | \
            xargs -I@ bash -c "
                NAME=\$(basename -- @ .tar.zst |awk -F_ -vVENDOR=$DV '{print VENDOR\"_\"\$1\"_\"\$3}');
                mkdir -p $XDG_RUNTIME_DIR/runner/baseline/\$NAME && tar --zstd -xf @ -C \$_;
            "
    done
    fd -iHx /usr/bin/rm {} \; --regex "\.tar\.zst$" --changed-before 6month -- $TEST_RESULT_DIR
fi
