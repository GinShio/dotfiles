#!/usr/bin/env bash

trap "sudo -k; source $(dirname ${BASH_SOURCE[0]})/../common/unproxy.sh" EXIT
source $(dirname ${BASH_SOURCE[0]})/../common/common.sh
source $(dirname ${BASH_SOURCE[0]})/../common/proxy.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper ref
sudo -Sv <<<$ROOT_PASSPHRASE
zypper lr |sed '1,4d' |awk '{print $3}' |grep 'openSUSE:' |xargs -I@ sudo -E zypper up -y --repo @
sudo -Sv <<<$ROOT_PASSPHRASE
sudo zypper up -y
