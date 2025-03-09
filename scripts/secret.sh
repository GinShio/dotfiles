#!/usr/bin/env bash

ROOT_DIR=$HOME/dotfiles

args=`getopt -l "encrypt,decrypt" -a -o "ed" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -e|--encrypt) method="encrypt"; regexp="*"; shift;;
        -d|--decrypt) method="decrypt"; regexp=".*\.ssl$"; shift;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)

function encrypt_secret_file() {
  local relative_dir=$1    
  local filename=$2
  mkdir -p $outdir/$relative_dir
  bash $ROOT_DIR/scripts/encrypt.sh --$method --tmpdir $tmpdir --input $indir/$relative_dir/$filename --outdir $outdir/$relative_dir
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

encrypt_dir=$ROOT_DIR/secret
decrypt_dir=$ROOT_DIR/secret_plain
if [[ "$method" = "decrypt" ]]; then
  outdir=$decrypt_dir
  indir=$encrypt_dir
else
  outdir=$encrypt_dir
  indir=$decrypt_dir
fi
secret_files_recursively $indir
