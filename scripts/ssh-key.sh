#!/usr/bin/env bash

ROOT_DIR=$HOME/dotfiles
source $ROOT_DIR/.env

function deploy_key() {
    openssl enc -aes-256-cbc -d -a -kfile $ROOT_DIR/.kfile -salt -pbkdf2 -iter 100000 -in $ROOT_DIR/keys/ssh.tar.zst.ssl -out ./ssh.tar.zst
    tar --zstd -xf ssh.tar.zst
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
    openssl enc -aes-256-cbc -e -a -kfile $ROOT_DIR/.kfile -salt -pbkdf2 -iter 100000 -in     $FILENAME.tar.zst -out $FILENAME.tar.zst.ssl
    rsync --remove-source-files $FILENAME.tar.zst.ssl $ROOT_DIR/keys
    cd $ROOT_DIR/keys
    ln -sf $FILENAME.tar.zst.ssl ssh.tar.zst.ssl
}

args=`getopt -l "deploy,update" -a -o "du" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -d|--deploy) deploy=1; shift;;
        -u|--update) update=1; shift;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [[ 0 -ne $update ]]; then
    echo ${PERSONAL_EMAIL:?Missing personal email.} >/dev/null
    echo ${WORK_EMAIL:?Missing work email.} >/dev/null
    echo ${WORK_ORGNAIZATION:?Missing work orgnaization.} >/dev/null
    echo ${FILENAME:-ssh-in-$(date "+%Y")} >/dev/null
fi

echo $PASSPHRASE >$ROOT_DIR/.kfile
cd $(mktemp -d)

if [[ 0 -ne $update ]]; then
    update_key
elif [[ 0 -ne $deploy ]]; then
    deploy_key
fi
rm $ROOT_DIR/.kfile
