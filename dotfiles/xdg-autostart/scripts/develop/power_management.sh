#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh
trap "sudo -k" EXIT

sudo -Sv <<<$ROOT_PASSPHRASE
for device in $(ls -1 -d /sys/class/power_supply/BAT*); do
    sudo bash -c "echo 60 > $device/charge_control_start_threshold"
    sudo bash -c "echo 80 > $device/charge_control_end_threshold"
    powerprofilesctl configure-action --enable amdgpu_dpm
    powerprofilesctl configure-action --enable amdgpu_panel_power
done
