#!/usr/bin/env bash

bash {{@@ _dotfile_abs_dst @@}}/scripts/develop/power_management.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/develop/mount_samba.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/develop/copy_gpu_tests.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/develop/create_terminal.sh
