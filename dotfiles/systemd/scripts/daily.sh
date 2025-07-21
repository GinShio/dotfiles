#!/usr/bin/env bash

bash {{@@ _dotfile_abs_dst @@}}/scripts/daily/update-system.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/daily/cleanup-test-results.sh

now_timestamps=$(date +%s)
bash {{@@ _dotfile_abs_dst @@}}/scripts/daily/update-projects.sh
bash {{@@ _dotfile_abs_dst @@}}/scripts/daily/gpu_test-wrapper.sh $now_timestamps

#systemctl reboot
