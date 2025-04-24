#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh
now_timestamps=$1
now_timestamps=${now_timestamps:-$(date +%s)}

# Testing every 3 days
[[ 0 -eq $(( 10#$(date +%j) % 3 )) ]] || exit 0

drivers_tuple=(
    # vendor,glapi,kits,driver
    llpc,vk,"deqp",$AMDVLK_PATH
    mesa,vk,"deqp",$RADV_PATH
    #swrast,vk,"deqp",$LVP_PATH
    llpc,zink,"deqp",$ZINK_PATH:$AMDVLK_PATH
    mesa,zink,"deqp",$ZINK_PATH:$RADV_PATH
    #swrast,zink,"deqp",$ZINK_PATH:$LVP_PATH
    #mesa,gl,"deqp:piglit",$RADEONSI_PATH
    #llpc,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$AMDVLK_PATH
    #mesa,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$RADV_PATH
    #swrast,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$LVP_PATH
) # drivers tuple declare end

function check_driver() {
    local driver=$1
    local driver_built_time=$(stat -c "%Y" "$driver")
    if [[ ! -e $driver || $now_timestamps -ge $driver_built_time ]]; then
        return 1
    fi
    return 0
}

declare -a test_infos=()
for elem in ${drivers_tuple[@]}; do
    IFS=',' read vendor glapi testkits drivers <<< "${elem}"
    for driver in $(tr ':' '\t' <<<"$drivers"); do
        check_driver "$driver" || continue
    done
    test_infos+=("$vendor,$glapi,$testkits")
done
tmux send-keys -t runner "bash $DOTFILES_ROOT_PATH/scripts/daily/gpu_test.sh '${test_infos[*]}'" ENTER
