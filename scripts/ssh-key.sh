#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh

function deploy_key() {
    rsync -L $DOTFILES_ROOT_PATH/keys/ssh.tar.zst $tmpdir
    tar --zstd -xf ssh.tar.zst
    rm -rf ssh.tar.zst{,.ssl}
    rsync --remove-source-files * $HOME/.ssh
}

function update_key() {
    declare -a key_items=(
      "${WORK_ORGNAIZATION}-pri-ssh"
      "${WORK_ORGNAIZATION}-pri-git"
      "${WORK_ORGNAIZATION}-pub-git"
      "personal-git"
      "personal-ssh"
    )

    for item in ${key_items[@]}; do
        if [[ "$item" =~ "$WORK_ORGNAIZATION" ]]
        then comment="$item-${WORK_EMAIL}"
        elif [[ "$item" =~ "personal" ]]
        then comment="$item-${PERSONAL_EMAIL}"
        else comment="$item"
        fi
        ssh-keygen -C "$comment" -t ed25519 -f "$PWD/$item" -N ""
    done
    chmod a-w *
    tar -cf - * |zstd -z -19 --ultra --quiet -o $FILENAME.tar.zst
    rsync --remove-source-files $FILENAME.tar.zst $DOTFILES_ROOT_PATH/keys
    cd $DOTFILES_ROOT_PATH/keys
    ln -sf $FILENAME.tar.zst ssh.tar.zst
}

args=`getopt -l "deploy,update,tmpdir:" -a -o "duT" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -d|--deploy) deploy=1; shift;;
        -u|--update) update=1; shift;;
        -T|--tmpdir) tmpdir=$2; shift 2;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [[ 0 -ne $update ]]; then
    echo ${PERSONAL_EMAIL:?Missing personal email.} >/dev/null
    echo ${WORK_EMAIL:?Missing work email.} >/dev/null
    echo ${WORK_ORGNAIZATION:?Missing work orgnaization.} >/dev/null
    FILENAME=${FILENAME:-ssh-$(date "+%Y")}
    WORK_ORGNAIZATION=$(tr '[:upper:]' '[:lower:]' <<<$WORK_ORGNAIZATION)
fi

if [ -z "$tmpdir" ]
then tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)
fi
cd $tmpdir

if [[ 0 -ne $update ]]; then
    update_key
elif [[ 0 -ne $deploy ]]; then
    deploy_key
fi
