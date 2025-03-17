#!/usr/bin/env bash

get_dotfiles_path() {
    local script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    realpath $script_dir/../..
}

export DOTFILES_ROOT_PATH=$(get_dotfiles_path)
set -o allexport
source $DOTFILES_ROOT_PATH/config.d/env
source $DOTFILES_ROOT_PATH/config.d/env.driver
set +o allexport
