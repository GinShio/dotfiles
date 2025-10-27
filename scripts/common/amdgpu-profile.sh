#!/usr/bin/env bash

PROFILE=${1:-auto}

trap "sudo -k" EXIT
export SUDO_ASKPASS=$(dirname ${BASH_SOURCE[0]})/common/get-root-passphrase.sh

for device in $(ls -1 -d /sys/module/amdgpu/drivers/pci:amdgpu/*/); do
    if ! [ -e $device/device ]; then
        continue
    fi
    echo $PROFILE |sudo -A -- tee $device/power_dpm_force_performance_level
done
