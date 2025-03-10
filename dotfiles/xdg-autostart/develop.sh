#!/usr/bin/env bash

source $HOME/dotfiles/config.d/env
sudo -Sv <<<$ROOT_PASSPHRASE
sudo mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.imm.fstab
sudo bash -c "nohup mount --all --fstab $HOME/Public/.config.d/{{@@ profile @@}}.nohup.fstab &"

tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s runner -c $XDG_RUNTIME_DIR/runner
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s build -c $HOME/Projects
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s emacs -c $HOME

DEVICE_REGEXP='0x[0-9a-fA-F]{4}'
DATA_REGEXP='[1-9][0-9][0-9]{3}-(0[1-9]|1[0-2])-([1-2][0-9]|0[1-9]|3[0-1])'
TESTKIT_REGEXP='((piglit|deqp)-(vk|gl|zink))'
DEVICE_ID=$(vulkaninfo 2>/dev/null |awk '/deviceID[[:blank:]]*=/ {print $NF; exit}')

if ! [ -z $TEST_RESULT_DIR ]; then
    DEVICE_VENDORS=(llpc mesa)
    for DV in ${DEVICE_VENDORS[@]}; do
        if ! [ -e $TEST_RESULT_DIR ] || ! [ -e $TEST_RESULT_DIR/$DV ]; then
            continue
        fi
        fd -iHx /usr/bin/echo {} \; --regex "${TESTKIT_REGEXP}_${DEVICE_ID}_${DATA_REGEXP}.tar.zst" --changed-withid 8d -- $TEST_RESULT_DIR/$DV | \
            xargs -I@ bash -c "
                NAME=\$(basename -- @ .tar.zst |awk -F_ -vVENDOR=$DV '{print VENDOR\"_\"\$1\"_\"\$3}');
                mkdir -p $XDG_RUNTIME_DIR/runner/baseline/\$NAME && tar --zstd -xf @ -C \$_;
            "
    done
    fd -iHx /usr/bin/rm {} \; --regex "\.tar\.zst$" --changed-before 6month -- $TEST_RESULT_DIR
fi

cat <<-VKEXCLUDE >$XDG_RUNTIME_DIR/runner/deqp/vk-exclude.txt
api.txt
image/swapchain-mutable.txt
info.txt
query-pool.txt
video.txt
wsi.txt
VKEXCLUDE
tmux send-keys -t runner "copy-graphics-testcase --deqp --piglit --tool --vkd3d" ENTER
tmux send-keys -t emacs "emacs -nw" ENTER
