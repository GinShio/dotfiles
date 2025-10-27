#!/usr/bin/env bash

export SUDO_ASKPASS={{@@ _dotdrop_workdir @@}}/scripts/common/get-root-passphrase.sh
trap "sudo -k" EXIT

sudo -A -- mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.imm.fstab
# sudo -A -- bash -c "nohup mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.nohup.fstab &"
