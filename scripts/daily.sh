#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/update-system.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/update-hosts.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/cleanup-test-results.sh

now_timestamps=$(date +%s)
bash $DOTFILES_ROOT_PATH/scripts/daily/update-projects.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/gpu_test-wrapper.sh $now_timestamps

#systemctl reboot
