#!/usr/bin/env bash

args=`getopt -l "project:,skipbuild,skippull" -a -o "p:Ss" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -p|--project) project=$2; shift 2;;
        -s|--skippull) skippull=1; shift;;
        -S|--skipbuild) skipbuild=1; shift;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done
skippull=${skippull:-0}
skipbuild=${skipbuild:-0}

C_COMPILER=clang
CXX_COMPILER=clang++
LINKER=mold

project_filename=$(dirname ${BASH_SOURCE[0]})/project/$project.sh
if [ -f $project_filename ]; then
    source $project_filename
else
    echo "Not support project: $project"
    exit 0
fi

declare_$project
CMAKE_OPTIONS=(
  -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_C_COMPILER=$C_COMPILER
  -DCMAKE_C_FLAGS_INIT=$([[ "$C_COMPILER" = gcc ]] && echo "-fdiagnostics-color=always" || echo "-fcolor-diagnostics")
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER=$CXX_COMPILER
  -DCMAKE_CXX_FLAGS_INIT=$([[ "$CXX_COMPILER" = g++ ]] && echo "-fdiagnostics-color=always" || echo "-fcolor-diagnostics")
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_DEBUG=OFF
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=ON
)
declare -n project_info

for project_info in ${!project_info@}; do
    sourcedir=${project_info[sourcedir]}
    builddir=${project_info[builddir]}
    if [[ 0 -eq $skippull ]] && [ -d $sourcedir ]; then
        git -C $sourcedir fetch origin --prune && git -C $sourcedir merge --ff-only origin/${project_info[branch]}
    elif [[ 0 -eq $skippull ]]; then
        git clone --recursive ${project_info[url]} $sourcedir && fish -c "set-git-urls --path=$sourcedir --contribute"
    else
        :
    fi
    status=$?
    if [[ 0 -ne $status ]]; then
        echo "Failed to clone/update $project ($sourcedir)"
        exit 1
    fi

    if [ -z "$builddir" ] || [ ! -e $sourcedir ] || [[ 0 -ne $skipbuild ]]; then
        continue
    fi
    pushd $sourcedir 2>&1 >/dev/null
    if [ -d $builddir ]; then
        build_$project
    elif ! [ -e $builddir ]; then
        llvm_num_link=$(awk '/MemTotal/{targets = int($2 / (16 * 2^20)); print targets<1?1:targets}' /proc/meminfo)
        config_$project
    fi
    status=$?
    popd 2>&1 >/dev/null
    if [[ 0 -ne $status ]]; then
        echo "Failed to compile $project"
        exit 1
    fi
done
