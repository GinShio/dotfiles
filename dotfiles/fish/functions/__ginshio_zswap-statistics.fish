#!/usr/bin/env fish

source {{@@ _dotfile_abs_dst @@}}/functions/__ginshio_source-posix.fish

function zswap-statistics
    # Copy from https://unix.stackexchange.com/questions/406936/get-current-zswap-memory-usage-and-statistics.
    # Authored-by: Вадим Илларионов
    source-posix {{@@ _dotdrop_workdir @@}}/config.d/env
    bash -c 'sudo -Sv <<<$ROOT_PASSPHRASE'
    set -f MDL /sys/module/zswap
    set -f EN (sudo cat $MDL/parameters/enabled)
    function Show
        printf "========\n$argv[1]\n========\n"
        sudo grep -R . $argv[2] 2>/dev/null |sed "s|.*/||"
    end
    Show Settings $MDL
    if test $EN = "N"
        echo "\nzswap disabled"
        return
    end
    set -f DBG /sys/kernel/debug/zswap
    set -f PAGE (math "$(sudo cat $DBG/stored_pages) x 4096")
    set -f POOL (sudo cat $DBG/pool_total_size)
    Show Stats    $DBG
    printf "\nCompression ratio: "
    if test $POOL -gt 0
        echo "scale=3;$PAGE/$POOL" | bc
    else
        echo "0"
    end
    desource-posix {{@@ _dotdrop_workdir @@}}/config.d/env
    sudo -k
end
