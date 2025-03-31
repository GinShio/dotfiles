#!/usr/bin/env bash

trap "sudo -k" EXIT
source $(dirname $0)/../common/common.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper ref
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper up -y
