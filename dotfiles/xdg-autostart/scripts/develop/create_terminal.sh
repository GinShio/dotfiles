#!/usr/bin/env bash

tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s runner -c $XDG_RUNTIME_DIR/runner
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s build -c $HOME/Projects
tmux new-session -d -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -s emacs -c $HOME

tmux send-keys -t emacs "emacsclient -nw --eval '(doom/load-session \"$HOME/.config/emacs/.local/etc/workspaces/projs\")'" ENTER
