#!/usr/bin/env fish

function zswap-statistics
    # Copy from https://unix.stackexchange.com/questions/406936/get-current-zswap-memory-usage-and-statistics.
    # Authored-by: Вадим Илларионов
    set -fx SUDO_ASKPASS {{@@ _dotdrop_workdir @@}}/scripts/common/get-root-passphrase.sh
    set -f MDL /sys/module/zswap
    set -f EN (sudo -A -- cat $MDL/parameters/enabled)
    function Show
        printf "========\n$argv[1]\n========\n"
        sudo -A -- grep -R . $argv[2] 2>/dev/null |sed "s|.*/||"
    end
    Show Settings $MDL
    if test $EN = "N"
        echo "\nzswap disabled"
        return
    end
    set -f DBG /sys/kernel/debug/zswap
    set -f PAGE (math "$(sudo -A -- cat $DBG/stored_pages) x 4096")
    set -f POOL (sudo -A -- cat $DBG/pool_total_size)
    Show Stats    $DBG
    printf "\nCompression ratio: "
    if test $POOL -gt 0
        echo "scale=3;$PAGE/$POOL" | bc
    else
        echo "0"
    end
    sudo -k
end
