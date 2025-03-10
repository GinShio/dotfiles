#!/usr/bin/env bash

ROOT_DIR=$HOME/dotfiles
source $ROOT_DIR/config.d/env

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

if [ -z "$tmpdir" ]
then tmpdir=$(mktemp -d /tmp/dotfiles-XXXXXXXXX.d)
fi
echo $PASSPHRASE >$tmpdir/.kfile
cd $tmpdir

if [[ "$method" = "encrypt" ]]; then
    if [ -z "$outdir" ]
    then output="$filename.ssl"
    else output="$outdir/$(basename $filename).ssl"
    fi
    openssl enc -aes-256-cbc -e -a -kfile $tmpdir/.kfile -salt -pbkdf2 -iter 100000 -in $filename -out $output
elif [[ "$method" = "decrypt" ]]; then
    output="$(basename -s .ssl $filename)"
    if [ -z "$outdir" ]
    then output="$(dirname $filename)/$output"
    else output="$outdir/$output"
    fi
    openssl enc -aes-256-cbc -d -a -kfile $tmpdir/.kfile -salt -pbkdf2 -iter 100000 -in $filename -out $output
fi
rm $tmpdir/.kfile
