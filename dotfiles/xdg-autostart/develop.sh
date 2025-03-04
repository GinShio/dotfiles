#!/usr/bin/env bash

tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s runner -c $XDG_RUNTIME_DIR/runner
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s build -c $HOME/Projects
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s emacs -c $HOME

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
