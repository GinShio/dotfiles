#!/usr/bin/env bash

source {{@@ _dotdrop_workdir @@}}/scripts/common/common.sh

if [ -e $HOME/Projects/amdvlk ] && [ -e $HOME/Projects/Builder ]; then
    python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl monorepo
    if [ $? -eq 0 ]; then
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --release
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --debug --tool
    fi
fi

source {{@@ _dotdrop_workdir @@}}/scripts/common/proxy.sh
trap "source {{@@ _dotdrop_workdir @@}}/scripts/common/unproxy.sh" EXIT
project_list=(mesa llvm)
for project in ${project_list[@]}; do
    bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=$project --skipbuild
    if [ $? -eq 0 ]; then
        bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=$project --skippull
    fi
done
