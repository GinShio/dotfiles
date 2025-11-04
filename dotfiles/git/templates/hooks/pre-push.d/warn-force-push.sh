#!/usr/bin/env bash

# git config --local hooks.protected.enabled 1
ENABLE=$(git config --get hooks.protected.enabled)
if [ -z $ENABLE ] || [ $ENABLE -eq 0 ]; then
    exit
fi

if [[ $push_command =~ $FORCE_PUSH_CMD ]]; then
    echo "Think before you type."
    $(prompt-to-confirm)
    status=$?
    if [ $status -ne 0 ]; then
        echo "Abort..."
        exit $status
    fi
fi
