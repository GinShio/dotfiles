#!/usr/bin/env bash

args=`getopt -l "project:,skipbuild" -a -o "p:S" -- $@`
eval set -- $args
while true ; do
    case "$1" in
        -p|--project) project=$2; shift 2;;
        -S|--skipbuild) skipbuild=1; shift;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

src=$HOME/Projects/$project

CMAKE_OPTIONS=(
  "-GNinja Multi-Config"
  -DCMAKE_DEFAULT_BUILD_TYPE=Release
  -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=mold
  -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=mold
  -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=mold
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_C_COMPILER=gcc
  -DCMAKE_C_FLAGS_INIT=-fdiagnostics-color=always
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER=g++
  -DCMAKE_CXX_FLAGS_INIT=-fdiagnostics-color=always
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_DEBUG=OFF
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=ON
)

case $project in
    mesa)
        url='https://gitlab.freedesktop.org/mesa/mesa.git'
        branch=main
        ;;
    llvm)
        url='github:llvm/llvm-project.git'
        branch=main
        ;;
    umr)
        url='https://gitlab.freedesktop.org/tomstdenis/umr.git'
        branch=main
        ;;
    deqp)
        url='github:KhronosGroup/VK-GL-CTS.git'
        branch=main
        ;;
    piglit)
        url='https://gitlab.freedesktop.org/mesa/piglit.git'
        branch=main
        ;;
    runner)
        url='https://gitlab.freedesktop.org/mesa/deqp-runner.git'
        branch=main
        ;;
    vkd3d)
        url='github:HansKristian-Work/vkd3d-proton.git'
        branch=master
        ;;
    slang)
        url='github:shader-slang/slang.git'
        branch=master
        ;;
    *)
        exit 0
        ;;
esac

cd $HOME/Projects/$project

if [ -d $src ]; then
    git fetch --all --prune && git merge --ff-only origin/$branch
else

    git clone --recursive $url $src
fi
status=$?
if [[ 0 -ne $status ]]; then
    echo "Failed to clone/update"
    exit 1
fi

pushd $HOME/Projects/$project 2>&1 >/dev/null
if [[ 0 -eq $skipbuild ]] && [ -d $src/_build ]; then
    case $project in
        mesa)
            meson compile -C $HOME/Projects/$project/_build/_rel
            meson install -C $HOME/Projects/$project/_build/_rel
            meson compile -C $HOME/Projects/$project/_build/_dbg
            meson install -C $HOME/Projects/$project/_build/_dbg
            ;;
        llvm)
            cmake --build $HOME/Projects/$project/_build/_dbg
            ;;
        umr)
            ;;
        deqp|piglit|slang)
            cmake --build $HOME/Projects/$project/_build --config Release
            ;;
        runner)
            cargo build --release --target-dir $HOME/Projects/runner/_build
            ;;
        vkd3d)
            meson compile -C $HOME/Projects/$project/_build/_rel
            ;;
    esac
elif ! [ -e $src/_build ]; then
    case $project in
        mesa)
            CC='ccache gcc' CXX='ccache g++' LDFLAGS='-fuse-ld=mold' \
                meson setup $HOME/Projects/mesa $HOME/Projects/mesa/_build/_rel \
                --libdir=lib --prefix $HOME/.local -Dbuildtype=release \
                -Dgallium-drivers=radeonsi,zink,llvmpipe -Dvulkan-drivers=amd,swrast \
                -Dgallium-opencl=disabled -Dgallium-rusticl=false
            CC='ccache gcc' CXX='ccache g++' LDFLAGS='-fuse-ld=mold' \
                meson setup $HOME/Projects/mesa $HOME/Projects/mesa/_build/_dbg \
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
        llvm)
            llvm_num_link=$(awk '/MemTotal/{targets = int($2 / (16 * 2^20)); print targets<1?1:targets}' /proc/meminfo)
            cmake -S$HOME/Projects/llvm/llvm -B$HOME/Projects/llvm/_build/_dbg -DCMAKE_BUILD_TYPE=Debug \
                -GNinja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
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
                -DLLVM_USE_LINKER=mold \
                -DCLANG_ENABLE_CIR=ON
            # -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='DirectX;SPIRV'
            ;;
        umr)
            url='https://gitlab.freedesktop.org/tomstdenis/umr.git'
            branch=main
            ;;
        deqp)
            python3 external/fetch_sources.py
            cmake -S$HOME/Projects/deqp -B$HOME/Projects/deqp/_build "${CMAKE_OPTIONS[@]}" -DDEQP_TARGET=default
            ;;
        piglit)
            cmake -S$HOME/Projects/piglit -B$HOME/Projects/piglit/_build "${CMAKE_OPTIONS[@]}"
            ;;
        runner)
            cargo build --release --target-dir $HOME/Projects/runner/_build
            ;;
        vkd3d)
            CC='ccache gcc' CXX='ccache g++' LDFLAGS='-fuse-ld=mold' \
            meson setup $HOME/Projects/vkd3d $HOME/Projects/vkd3d/_build/_rel \
            -Dbuildtype=release -Denable_tests=true -Denable_extras=false
            ;;
        slang)
            cmake -S$HOME/Projects/slang -B$HOME/Projects/slang/_build "${CMAKE_OPTIONS[@]}" -DSLANG_SLANG_LLVM_FLAVOR=DISABLE
            ;;
    esac
fi
status=$?
popd 2>&1 >/dev/null
if [[ 0 -ne $status ]]; then
    echo "Failed to compile"
    exit 1
fi
