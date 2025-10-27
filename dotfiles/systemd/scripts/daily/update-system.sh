#!/usr/bin/env bash

trap "sudo -k; source {{@@ _dotdrop_workdir @@}}/scripts/common/unproxy.sh" EXIT
export SUDO_ASKPASS={{@@ _dotdrop_workdir @@}}/scripts/common/get-root-passphrase.sh
source {{@@ _dotdrop_workdir @@}}/scripts/common/proxy.sh

sudo -AE -- zypper ref
zypper lr |awk 'NR > 4 && $3~/openSUSE:/ {print $3}' |xargs -I@ sudo -AE -- zypper up -y --repo @
sudo -A -- zypper up -y --allow-vendor-change
sudo -A -- zypper dup -y --allow-vendor-change
