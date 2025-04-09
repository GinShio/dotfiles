#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh
now_timestamps=$1
now_timestamps=${now_timestamps:-$(date +%s)}

# Testing every 3 days
[[ 0 -eq $(( 10#$(date +%j) % 3 )) ]] || exit 0

drivers_tuple=(
    # vendor,glapi,kits,driver
    #llpc,vk,"deqp",$AMDVLK_PATH
    mesa,vk,"deqp",$RADV_PATH
    #llpc,zink,"deqp",$AMDVLK_PATH
    mesa,zink,"deqp",$RADV_PATH
    #mesa,gl,"deqp:piglit",$RADEONSI_PATH
) # drivers tuple declare end

declare -a test_infos=()
for elem in ${drivers_tuple[@]}; do
    IFS=',' read vendor glapi testkits driver <<< "${elem}"
    if [[ ! -e $driver || $now_timestamps -ge $(stat -c "%Y" "$driver") ]]; then
        continue
    fi
    test_infos+=("$vendor,$glapi,$testkits")
done
tmux send-keys -t runner "bash $DOTFILES_ROOT_PATH/scripts/daily/gpu_test.sh '${test_infos[*]}'" ENTER
