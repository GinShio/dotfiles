#!/usr/bin/env bash

if [[ "$push_command" =~ ":" ]]; then
  LOCAL_BRANCH=${push_command%:*}
  export LOCAL_BRANCH=${LOCAL_BRANCH##* }
  REMOTE_BRANCH=${push_command##*:}
  export REMOTE_BRANCH=${REMOTE_BRANCH%% *}
else
  LOCAL_BRANCH=$(git rev-parse --abbrev-ref --remotes=$REMOTE_REF @{push} 2>/dev/null)
  export LOCAL_BRANCH=${LOCAL_BRANCH#*/}
  export REMOTE_BRANCH=$LOCAL_BRANCH
fi

if [[ $REMOTE_BRANCH =~ $PROTECTED_BRANCH ]]; then
    echo >&2 "Never push code directly to the protected branch ($REMOTE_BRANCH)!"
    exit 1
fi
