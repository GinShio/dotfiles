#!/usr/bin/env bash

if [[ $push_command =~ $FORCE_PUSH_CMD ]]; then
    echo "Think before you type."
    $(prompt-to-confirm)
    status=$?
    if [ $status -ne 0 ]; then
        echo "Abort..."
        exit $status
    fi
fi
