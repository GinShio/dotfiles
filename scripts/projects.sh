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

C_COMPILER=gcc
CXX_COMPILER=g++
LINKER=mold
CMAKE_OPTIONS=(
  "-GNinja Multi-Config"
  -DCMAKE_DEFAULT_BUILD_TYPE=Release
  -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=$LINKER
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_C_COMPILER=$C_COMPILER
  -DCMAKE_C_FLAGS_INIT=-fdiagnostics-color=always
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER=$CXX_COMPILER
  -DCMAKE_CXX_FLAGS_INIT=-fdiagnostics-color=always
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_DEBUG=OFF
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=ON
)

case $project in
    alive2)
        url='https://github.com/AliveToolkit/alive2.git'
        branch=master
        builddir=$HOME/Projects/$project/_build
        ;;
    deqp)
        url='https://github.com/KhronosGroup/VK-GL-CTS.git'
        branch=main
        builddir=$HOME/Projects/$project/_build
        ;;
    llvm)
        url='https://github.com/llvm/llvm-project.git'
        branch=main
        builddir=$HOME/Projects/$project/_build/_dbg
        ;;
    mesa)
        url='https://gitlab.freedesktop.org/mesa/mesa.git'
        branch=main
        builddir=$HOME/Projects/$project/_build
        ;;
    piglit)
        url='https://gitlab.freedesktop.org/mesa/piglit.git'
        branch=main
        builddir=$HOME/Projects/$project/_build
        ;;
    runner)
        url='https://gitlab.freedesktop.org/mesa/deqp-runner.git'
        branch=main
        builddir=$HOME/Projects/$project/_build
        ;;
    slang)
        url='https://github.com/shader-slang/slang.git'
        branch=master
        builddir=$HOME/Projects/$project/_build
        ;;
    umr)
        url='https://gitlab.freedesktop.org/tomstdenis/umr.git'
        branch=main
        builddir=$HOME/Projects/$project/_build
        ;;
    vkd3d)
        url='https://github.com/HansKristian-Work/vkd3d-proton.git'
        branch=master
        builddir=$HOME/Projects/$project/_build/_rel
        ;;
    *)
        exit 0
        ;;
esac

if [[ 0 -eq $skippull ]] && [ -d $HOME/Projects/$project ]; then
    git -C $HOME/Projects/$project fetch origin --prune && git -C $HOME/Projects/$project merge --ff-only origin/$branch
elif [[ 0 -eq $skippull ]]; then
    git clone --recursive $url $HOME/Projects/$project
else
    :
fi
status=$?
if [[ 0 -ne $status ]]; then
    echo "Failed to clone/update $project"
    exit 1
fi

pushd $HOME/Projects/$project 2>&1 >/dev/null
if [[ 0 -eq $skipbuild ]] && [ -d $builddir ]; then
    case $project in
        alive2|deqp|piglit|slang|umr)
            cmake --build $builddir --config Release
            ;;
        llvm)
            cmake --build $builddir
            ;;
        mesa)
            meson compile -C $builddir/_rel
            meson install -C $builddir/_rel
            meson compile -C $builddir/_dbg
            meson install -C $builddir/_dbg
            ;;
        runner)
            cargo build --release --target-dir $builddir
            ;;
        umr)
            ;;
        vkd3d)
            meson compile -C $builddir
            ;;
    esac
elif ! [ -e $builddir ]; then
    case $project in
        alive2)
            ( export ALIVE2_HOME=$HOME/Projects; \
              export LLVM2_HOME=$HOME/Projects/llvm; \
              export LLVM2_BUILD=$HOME/Projects/llvm/_build/_dbg; \
              cmake -S$HOME/Projects/alive2 -B$builddir "${CMAKE_OPTIONS[@]}" -DBUILD_TV=1 -DCMAKE_PREFIX_PATH=$LLVM2_BUILD; )
            ;;
        deqp)
            python3 external/fetch_sources.py
            cmake -S$HOME/Projects/deqp -B$builddir "${CMAKE_OPTIONS[@]}" -DDEQP_TARGET=default
            ;;
        llvm)
            llvm_num_link=$(awk '/MemTotal/{targets = int($2 / (16 * 2^20)); print targets<1?1:targets}' /proc/meminfo)
            cmake -S$HOME/Projects/llvm/llvm -B$builddir -DCMAKE_BUILD_TYPE=Debug \
                -GNinja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                -DCMAKE_C_COMPILER=$C_COMPILER -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
                -DBUILD_SHARED_LIBS=ON \
                -DLLVM_ENABLE_ASSERTIONS=ON \
                -DLLVM_BUILD_TESTS=ON \
                -DLLVM_BUILD_TOOLS=ON \
                -DLLVM_CCACHE_BUILD=ON \
                -DLLVM_ENABLE_PIC=ON \
                -DLLVM_ENABLE_PROJECTS='clang;mlir' \
                -DLLVM_ENABLE_RTTI=ON \
                -DLLVM_INCLUDE_TOOLS=ON \
                -DLLVM_OPTIMIZED_TABLEGEN=ON \
                -DLLVM_PARALLEL_LINK_JOBS:STRING=$llvm_num_link \
                -DLLVM_TARGETS_TO_BUILD='AMDGPU;RISCV;X86' \
                -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='DirectX;SPIRV' \
                -DLLVM_USE_LINKER=$LINKER \
                -DCLANG_ENABLE_CIR=ON \
                -DCLANG_ENABLE_HLSL=ON
            # -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='DirectX;SPIRV' -DCLANG_ENABLE_HLSL=ON
            ;;
        mesa)
            CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                meson setup $HOME/Projects/mesa $builddir/_rel \
                --libdir=lib --prefix $HOME/.local -Dbuildtype=release \
                -Dgallium-drivers=radeonsi,zink,llvmpipe -Dvulkan-drivers=amd,swrast \
                -Dgallium-opencl=disabled -Dgallium-rusticl=false
            CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                meson setup $HOME/Projects/mesa $builddir/_dbg \
                --libdir=lib --prefix $HOME/Projects/mesa/_build/_dbg -Dbuildtype=debug \
                -Dgallium-drivers=radeonsi,zink,llvmpipe -Dvulkan-drivers=amd,swrast \
                -Dgallium-opencl=disabled -Dgallium-rusticl=false
            # MESA_ROOT=$HOME/.local \
            #       LD_LIBRARY_PATH=$MESA_ROOT/lib LIBGL_DRIVERS_PATH=$MESA_ROOT/lib/dri \
            #       VK_DRIVER_FILES=$(eval echo "$MESA_ROOT/share/vulkan/icd.d/{radeon,lvp}_icd.x86_64.json" |tr ' ' ':') \
            #       MESA_SHADER_CACHE_DISABLE=true MESA_LOADER_DRIVER_OVERRIDE=radeonsi LIBGL_ALWAYS_SOFTWARE= VK_LOADER_DRIVERS_DISABLE= \
            #       RADV_DEBUG=nocache RADV_PERFTEST= \
            #       AMD_DEBUG= \
            #       LP_DEBUG= LP_PERF= \
            #       ACO_DEBUG= NIR_DEBUG= \
            #       dosomething
            #### If disable radv: VK_LOADER_DRIVERS_DISABLE='radeon*'
            ;;
        piglit)
            cmake -S$HOME/Projects/piglit -B$builddir "${CMAKE_OPTIONS[@]}"
            ;;
        runner)
            cargo build --release --target-dir $builddir
            ;;
        slang)
            cmake -S$HOME/Projects/slang -B$builddir "${CMAKE_OPTIONS[@]}" -DSLANG_SLANG_LLVM_FLAVOR=DISABLE
            ;;
        umr)
            cmake -S$HOME/Projects/umr -B$builddir "${CMAKE_OPTIONS[@]}" -DUMR_NO_GUI=ON -DUMR_STATIC_EXECUTABLE=ON
            ;;
        vkd3d)
            CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                meson setup $HOME/Projects/vkd3d $HOME/Projects/vkd3d/_build/_rel \
                -Dbuildtype=release -Denable_tests=true -Denable_extras=false
            ;;
    esac
fi
status=$?
popd 2>&1 >/dev/null
if [[ 0 -ne $status ]]; then
    echo "Failed to compile $project"
    exit 1
fi
