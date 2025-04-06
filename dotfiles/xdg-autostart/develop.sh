#!/usr/bin/env bash

bash {{@@ _dotdrop_workdir @@}}/scripts/autostart/mount_samba.sh
bash {{@@ _dotdrop_workdir @@}}/scripts/autostart/copy_test_baseline.sh
bash {{@@ _dotdrop_workdir @@}}/scripts/autostart/create_terminal.sh
