#!/usr/bin/env bash

trap "sudo -k; source {{@@ _dotdrop_workdir @@}}/common/unproxy.sh" EXIT
source {{@@ _dotdrop_workdir @@}}/common/common.sh
source {{@@ _dotdrop_workdir @@}}/common/proxy.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper ref
sudo -Sv <<<$ROOT_PASSPHRASE
zypper lr |sed '1,4d' |awk '{print $3}' |grep 'openSUSE:' |xargs -I@ sudo -E zypper up -y --repo @
sudo -Sv <<<$ROOT_PASSPHRASE
sudo zypper up -y
