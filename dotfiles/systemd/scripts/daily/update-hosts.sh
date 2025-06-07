#!/usr/bin/env bash

trap "sudo -k; source {{@@ _dotdrop_workdir @@}}/common/unproxy.sh" EXIT
source {{@@ _dotdrop_workdir @@}}/common/common.sh
source {{@@ _dotdrop_workdir @@}}/common/proxy.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo cp /etc/hosts.bkp /etc/hosts
sudo -E bash -c "curl -s https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |tee -a /etc/hosts"
