#!/usr/bin/env bash

get_dotfiles_path() {
    local script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    realpath $script_dir/../..
}

get_power_AC() {
    local online=$(upower -d |awk '/power_AC/ {print $NF}' |xargs -I@ upower -i @ |awk '/online:/ {print $NF}')
    if [ -z "$online" ]; then
        echo "yes"
    else
        echo $online
    fi
}
export -f get_power_AC

export DOTFILES_ROOT_PATH=$(get_dotfiles_path)
set -o allexport
source $DOTFILES_ROOT_PATH/config.d/env
source $DOTFILES_ROOT_PATH/config.d/env.driver
set +o allexport
