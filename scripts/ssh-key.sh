#!/usr/bin/env bash

ROOT_DIR=$HOME/dotfiles
source $ROOT_DIR/config.d/env

function deploy_key() {
    rsync -L $HOME/dotfiles/keys/ssh.tar.zst.ssl $tmpdir
    bash $ROOT_DIR/scripts/encrypt.sh -d -i ssh.tar.zst.ssl -T $tmpdir
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
    bash $ROOT_DIR/scripts/encrypt.sh -e -i $FILENAME.tar.zst -T $tmpdir
    rsync --remove-source-files $FILENAME.tar.zst.ssl $ROOT_DIR/keys
    cd $ROOT_DIR/keys
    ln -sf $FILENAME.tar.zst.ssl ssh.tar.zst.ssl
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
    echo ${FILENAME:-ssh-in-$(date "+%Y")} >/dev/null
    WORK_ORGNAIZATION=$(tr '[:upper:]' '[:lower:]' <<<$WORK_ORGNAIZATION)
fi

echo $PASSPHRASE >$ROOT_DIR/.kfile
if [ -z "$tmpdir" ]
then tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)
fi
cd $tmpdir

if [[ 0 -ne $update ]]; then
    update_key
elif [[ 0 -ne $deploy ]]; then
    deploy_key
fi
rm $ROOT_DIR/.kfile
