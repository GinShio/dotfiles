#!/usr/bin/env bash

bash {{@@ _dotfile_abs_dst @@}}/scripts/autostart/power_management.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/autostart/mount_samba.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/autostart/copy_gpu_tests.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/autostart/create_terminal.sh
