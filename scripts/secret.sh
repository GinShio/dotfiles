#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh

args=`getopt -l "encrypt,decrypt,profile:,subproject:" -a -o "edp:S:" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -e|--encrypt) method="encrypt"; regexp="*"; shift;;
        -d|--decrypt) method="decrypt"; regexp=".*\.ssl$"; shift;;
        -p|--profile) profile="$2"; shift 2;;
        -S|--subproject) subproject="$2"; shift 2;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

echo ${profile:?Missing profile, please set --profile PROFILE} >/dev/null

tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)

function encrypt_secret_file() {
  local relative_dir=$1
  local filename=$2
  mkdir -p $outdir/$relative_dir
  bash $DOTFILES_ROOT_PATH/scripts/common/encrypt.sh --$method --tmpdir $tmpdir --input $indir/$relative_dir/$filename --outdir $outdir/$relative_dir
}

function secret_files_recursively() {
  local workdir=$1
  for dir in $(find $workdir -maxdepth 1 -type d -not -path $workdir -printf '%f\n'); do
    pushd $workdir/$dir 2>&1 >/dev/null
    secret_files_recursively $PWD
    popd 2>&1 >/dev/null
  done
  local relative_dir=$(realpath $workdir --relative-to $indir)
  for file in $(find $workdir -maxdepth 1 -type f -not -path $workdir -printf '%f\n'); do
    encrypt_secret_file $relative_dir $file
  done
}

encrypt_dir=$DOTFILES_ROOT_PATH/secret
decrypt_dir=$DOTFILES_ROOT_PATH/secret_plain
if [[ "$method" = "decrypt" ]]; then
  outdir=$decrypt_dir/$profile
  indir=$encrypt_dir/$profile
else
  outdir=$encrypt_dir/$profile
  indir=$decrypt_dir/$profile
fi
if ! [ -z $subproject ]; then
  outdir=$outdir/$subproject
  indir=$indir/$subproject
fi
mkdir -p $outdir
mkdir -p $indir
secret_files_recursively $indir
