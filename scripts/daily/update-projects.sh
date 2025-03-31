#!/usr/bin/env bash

source $(dirname $0)/../common/common.sh

if [ -e $HOME/Projects/amdvlk ] && [ -e $HOME/Projects/Builder ]; then
    python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl monorepo
    if [ $? -eq 0 ]; then
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --release
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --debug --tool
    fi
fi
bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=mesa
bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project=llvm --skipbuild
