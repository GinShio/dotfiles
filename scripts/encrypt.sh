#!/usr/bin/env bash

source $(dirname $0)/common.sh

args=`getopt -l "input:,outdir:,tmpdir:,encrypt,decrypt" -a -o "i:o:T:ed" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -i|--input) filename=$2; shift 2;;
        -o|--outdir) outdir=$2; shift 2;;
        -T|--tmpdir) tmpdir=$2; shift 2;;
        -e|--encrypt) method="encrypt"; shift;;
        -d|--decrypt) method="decrypt"; shift;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

echo ${filename:?Missing input file.} >/dev/null

get_encrypt_iv() {
    local get_iv_dword='od -An -N8 -tx8 -d /dev/urandom 2>/dev/null |head -n1'
    local format=""
    declare -a ivs=()
    for i in {1..2}; do
        ivs+=$(eval $get_iv_dword)
        format="${format}%s"
    done
    printf "$format" ${ivs[@]}
}

get_decrypt_iv() {
    local filename=$1
    head -n1 $filename
}

if [ -z "$tmpdir" ]
then tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)
fi
echo $PASSPHRASE >$tmpdir/.kfile

if [[ "$method" = "encrypt" ]]; then
    if [ -z "$outdir" ]
    then output="$filename.ssl"
    else output="$outdir/$(basename $filename).ssl"
    fi
    iv=$(get_encrypt_iv)
    echo $iv >$output
    openssl enc -aes-256-ctr -e -a -kfile $tmpdir/.kfile -iv $iv -salt -pbkdf2 -iter 100000 -in $filename -out - >>$output
elif [[ "$method" = "decrypt" ]]; then
    output="$(basename -s .ssl $filename)"
    if [ -z "$outdir" ]
    then output="$(dirname $filename)/$output"
    else output="$outdir/$output"
    fi
    iv=$(get_decrypt_iv $filename)
    tail -n+2 $filename |openssl enc -aes-256-ctr -d -a -kfile $tmpdir/.kfile -iv $iv -salt -pbkdf2 -iter 100000 -in - -out $output
fi
rm $tmpdir/.kfile
