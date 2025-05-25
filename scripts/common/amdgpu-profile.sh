#!/usr/bin/env bash

PROFILE=${1:-auto}

for device in $(ls -1 -d /sys/module/amdgpu/drivers/pci:amdgpu/*/); do
    if ! [ -e $device/device ]; then
        continue
    fi
    echo $PROFILE >$device/power_dpm_force_performance_level
done
