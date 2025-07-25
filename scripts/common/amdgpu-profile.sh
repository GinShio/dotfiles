#!/usr/bin/env bash

PROFILE=${1:-auto}

source $(dirname ${BASH_SOURCE[0]})/common.sh
trap "sudo -k" EXIT
sudo -Sv <<<$ROOT_PASSPHRASE

for device in $(ls -1 -d /sys/module/amdgpu/drivers/pci:amdgpu/*/); do
    if ! [ -e $device/device ]; then
        continue
    fi
    echo $PROFILE |sudo tee $device/power_dpm_force_performance_level
done
