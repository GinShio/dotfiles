#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh
trap "sudo -k" EXIT

sudo -Sv <<<$ROOT_PASSPHRASE
sudo mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.imm.fstab
# sudo bash -c "nohup mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.nohup.fstab &"
