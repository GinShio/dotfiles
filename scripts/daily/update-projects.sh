#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/../common/common.sh

if [ -e $HOME/Projects/amdvlk ] && [ -e $HOME/Projects/Builder ]; then
    python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl monorepo
    if [ $? -eq 0 ]; then
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --release
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --debug --tool
    fi
fi

project_list=(mesa llvm)
for project in ${project_list[@]}; do
    source $(dirname ${BASH_SOURCE[0]})/../common/proxy.sh
    bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=$project --skipbuild
    status=$?
    source $(dirname ${BASH_SOURCE[0]})/../common/unproxy.sh
    if [ $status -eq 0 ]; then
        bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=$project --skippull
    fi
done
