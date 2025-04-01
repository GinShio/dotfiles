#!/usr/bin/env bash

source $(dirname $0)/common/common.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/update-system.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/update-hosts.sh

now_timestamps=$(date +%s)
bash $DOTFILES_ROOT_PATH/scripts/daily/update-projects.sh
bash $DOTFILES_ROOT_PATH/scripts/daily/test-wrapper.sh $now_timestamps

#systemctl reboot
