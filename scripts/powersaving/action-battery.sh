#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh

bash $DOTFILES_ROOT_PATH/scripts/common/amdgpu-profile.sh "low"
