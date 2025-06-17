#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh
now_timestamps=$1
now_timestamps=${now_timestamps:-$(date +%s)}

# Testing every 3 days
[[ 0 -eq $(( 10#$(date +%j) % 3 )) ]] || exit 0
[[ "yes" = $(get_power_AC) ]] || exit 0

drivers_tuple=(
    # vendor,glapi,kits,driver
    llpc,vk,"deqp",$AMDVLK_PATH
    mesa,vk,"deqp",$RADV_PATH
    #swrast,vk,"deqp",$LVP_PATH
    llpc,zink,"deqp",$ZINK_PATH:$AMDVLK_PATH
    mesa,zink,"deqp",$ZINK_PATH:$RADV_PATH
    #swrast,zink,"deqp",$ZINK_PATH:$LVP_PATH
    mesa,gl,"deqp",$RADEONSI_PATH
    #llpc,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$AMDVLK_PATH
    #mesa,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$RADV_PATH
    #swrast,vkcl,"cts",$RUSTICL_PATH:$ZINK_PATH:$LVP_PATH
) # drivers tuple declare end

function check_driver() {
    local drivers_str=$1
    IFS=':'; local drivers=($drivers_str); IFS="$old_ifs"
    local delimiters=$(tr -dc ':'<<<"$drivers_str")
    local cnt=${#delimiters}
    for (( idx=0; idx<=cnt; idx++ )); do
        local driver=${drivers[idx]}
        ([[ ! -z "$driver" ]] && [[ -e "$driver" ]] && [[ $now_timestamps -lt $(stat -c "%Y" "$driver") ]]) || return 1
    done
    return 0
}

declare -a test_infos=()
for elem in ${drivers_tuple[@]}; do
    IFS=',' read vendor glapi testkits drivers <<< "${elem}"
    check_driver "$drivers" || continue
    test_infos+=("$vendor,$glapi,$testkits")
done

bash $DOTFILES_ROOT_PATH/scripts/common/amdgpu-profile.sh 'high'
cmd="bash {{@@ _dotfile_abs_dst @@}}/scripts/daily/gpu_test.sh '${test_infos[@]}'; bash $DOTFILES_ROOT_PATH/scripts/common/amdgpu-profile.sh 'auto'"
tmux send-keys -t runner "$cmd" ENTER
