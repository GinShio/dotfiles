#!/usr/bin/env bash

if [[ $CURRENT_BRANCH =~ $PROTECTED_BRANCH ]]; then
  echo "Commit to protected branch ($CURRENT_BRANCH), think before you type."
  $(prompt-to-confirm)
  status=$?
  if [ $status -ne 0 ]; then
    echo "Abort..."
    exit $status
  fi
fi
