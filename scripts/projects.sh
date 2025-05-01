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

case $project in
    alive2)
        declare -A project_info0=(
            [url]='https://github.com/AliveToolkit/alive2.git'
            [branch]=master
            [sourcedir]=$HOME/Projects/compiler/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    deqp)
        declare -A project_info0=(
            [url]='https://github.com/KhronosGroup/VK-GL-CTS.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    iree)
        declare -A project_info0=(
            [url]='https://github.com/iree-org/iree.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/compiler/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build/_dbg
        ;;
    llvm)
        declare -A project_info0=(
            [url]='https://github.com/llvm/llvm-project.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/compiler/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build/_dbg
        ;;
    mesa)
        declare -A project_info0=(
            [url]='https://gitlab.freedesktop.org/mesa/mesa.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    piglit)
        declare -A project_info0=(
            [url]='https://gitlab.freedesktop.org/mesa/piglit.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    runner)
        declare -A project_info0=(
            [url]='https://gitlab.freedesktop.org/mesa/deqp-runner.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    slang)
        declare -A project_info0=(
            [url]='https://github.com/shader-slang/slang.git'
            [branch]=master
            [sourcedir]=$HOME/Projects/compiler/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    spirv-tools)
        declare -A project_info0=(
            [url]='https://github.com/KhronosGroup/SPIRV-Tools.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        declare -A project_info1=(
            [url]='https://github.com/KhronosGroup/SPIRV-Headers.git'
            [branch]=main
            [sourcedir]=${project_info0[sourcedir]}/external/spirv-headers
        )
        ;;
    umr)
        declare -A project_info0=(
            [url]='https://gitlab.freedesktop.org/tomstdenis/umr.git'
            [branch]=main
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build
        ;;
    vkd3d)
        declare -A project_info0=(
            [url]='https://github.com/HansKristian-Work/vkd3d-proton.git'
            [branch]=master
            [sourcedir]=$HOME/Projects/khronos3d/$project
        )
        project_info0[builddir]=${project_info0[sourcedir]}/_build/_rel
        ;;
    *)
        exit 0
        ;;
esac
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

    if [ -z "$builddir" ]; then
        continue
    fi
    pushd $sourcedir 2>&1 >/dev/null
    if [[ 0 -eq $skipbuild ]] && [ -d $builddir ]; then
        case $project in
            alive2|deqp|piglit|slang|spirv-tools|umr)
                cmake --build $builddir --config Release
                ;;
            iree|llvm)
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
    else
    if ! [ -e $builddir ]; then
        llvm_num_link=$(awk '/MemTotal/{targets = int($2 / (16 * 2^20)); print targets<1?1:targets}' /proc/meminfo)
        case $project in
            alive2)
                ( export ALIVE2_HOME=$HOME/Projects/compiler; \
                  export LLVM2_HOME=$ALIVE2_HOME/llvm; \
                  export LLVM2_BUILD=$LLVM2_HOME/_build/_dbg; \
                  cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DBUILD_TV=1 -DCMAKE_PREFIX_PATH=$LLVM2_BUILD; )
                ;;
            deqp)
                python3 external/fetch_sources.py
                if [ 0 -eq $? ]; then
                    cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release -DCMAKE_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DDEQP_TARGET=default
                fi
                ;;
            iree)
                # if wants to use the trunk llvm, please use: CMAKE_PREFIX_PATH=$HOME/Projects/llvm/_build/_dbg/lib/cmake
                cmake -S$sourcedir -B$builddir -DCMAKE_INSTALL_PREFIX=$sourcedir/_install -DCMAKE_BUILD_TYPE=Debug -GNinja "${CMAKE_OPTIONS[@]}" \
                    -DIREE_BUILD_COMPILER=ON -DIREE_BUILD_TESTS=ON -DIREE_BUILD_SAMPLES=ON \
                    -DIREE_BUILD_PYTHON_BINDINGS=OFF -DIREE_BUILD_BINDINGS_TFLITE=OFF -DIREE_BUILD_BINDINGS_TFLITE_JAVA=OFF \
                    -DIREE_TARGET_BACKEND_DEFAULTS=OFF -DIREE_TARGET_BACKEND_LLVM_CPU=ON -DIREE_TARGET_BACKEND_VULKAN_SPIRV=ON \
                    -DIREE_HAL_DRIVER_DEFAULTS=OFF -DIREE_HAL_DRIVER_LOCAL_SYNC=ON -DIREE_HAL_DRIVER_LOCAL_TASK=ON -DIREE_HAL_DRIVER_VULKAN=ON \
                    -DIREE_INPUT_STABLEHLO=ON -DIREE_INPUT_TORCH=ON -DIREE_INPUT_TOSA=ON \
                    -DIREE_BUILD_BUNDLED_LLVM=ON -DLLVM_OPTIMIZED_TABLEGEN=ON -DLLVM_PARALLEL_LINK_JOBS:STRING=$llvm_num_link
                ;;
            llvm)
                cmake -S$sourcedir/llvm -B$builddir -DCMAKE_BUILD_TYPE=Debug -GNinja "${CMAKE_OPTIONS[@]}" \
                    -DBUILD_SHARED_LIBS=ON \
                    -DLLVM_ENABLE_ASSERTIONS=ON \
                    -DLLVM_BUILD_TESTS=ON \
                    -DLLVM_BUILD_TOOLS=ON \
                    -DLLVM_CCACHE_BUILD=ON \
                    -DLLVM_ENABLE_PIC=ON \
                    -DLLVM_ENABLE_PROJECTS='clang;mlir;lld' \
                    -DLLVM_ENABLE_RTTI=ON \
                    -DLLVM_INCLUDE_TOOLS=ON \
                    -DLLVM_OPTIMIZED_TABLEGEN=ON \
                    -DLLVM_PARALLEL_LINK_JOBS:STRING=$llvm_num_link \
                    -DLLVM_TARGETS_TO_BUILD='AMDGPU;RISCV;X86' \
                    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='DirectX;SPIRV' \
                    -DLLVM_USE_LINKER=$LINKER \
                    -DCLANG_ENABLE_CIR=ON \
                    -DCLANG_ENABLE_HLSL=ON
                ;;
            mesa)
                CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                    meson setup $sourcedir $builddir/_rel \
                    --libdir=lib --prefix $HOME/.local -Dbuildtype=release \
                    -Dgallium-drivers=radeonsi,zink,llvmpipe -Dvulkan-drivers=amd,swrast -Dgallium-rusticl=true
                CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                    meson setup $sourcedir $builddir/_dbg \
                    --libdir=lib --prefix $builddir/_dbg -Dbuildtype=debug \
                    -Dgallium-drivers=radeonsi,zink,llvmpipe -Dvulkan-drivers=amd,swrast -Dgallium-rusticl=true
                # MESA_ROOT=$HOME/.local \
                #       LD_LIBRARY_PATH=$MESA_ROOT/lib LIBGL_DRIVERS_PATH=$MESA_ROOT/lib/dri \
                #       VK_DRIVER_FILES=$(eval echo "$MESA_ROOT/share/vulkan/icd.d/{radeon,lvp}_icd.x86_64.json" |tr ' ' ':') VK_LOADER_DRIVERS_DISABLE= \
                #       OCL_ICD_FILENAMES=$MESA_ROOT/lib/libRusticlOpenCL.so RUSTICL_ENABLE=zink \
                #       MESA_SHADER_CACHE_DISABLE=true MESA_LOADER_DRIVER_OVERRIDE=radeonsi LIBGL_ALWAYS_SOFTWARE= \
                #       RADV_DEBUG=nocache RADV_PERFTEST= AMD_DEBUG= \
                #       LP_DEBUG= LP_PERF= RUSTICL_DEBUG= \
                #       ACO_DEBUG= NIR_DEBUG= \
                #       dosomething
                ;;
            piglit)
                cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}"
                ;;
            runner)
                cargo build --release --target-dir $builddir
                ;;
            slang)
                cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DSLANG_SLANG_LLVM_FLAVOR=DISABLE
                ;;
            spirv-tools)
                cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DSPIRV_COLOR_TERMINAL=ON
                ;;
            umr)
                cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DUMR_NO_GUI=ON -DUMR_STATIC_EXECUTABLE=ON
                ;;
            vkd3d)
                CC="ccache $C_COMPILER" CXX="ccache $CXX_COMPILER" LDFLAGS="-fuse-ld=$LINKER" \
                    meson setup $sourcedir $builddir \
                    -Dbuildtype=release -Denable_tests=true -Denable_extras=false
                ;;
        esac
    fi
    fi
    status=$?
    popd 2>&1 >/dev/null
    if [[ 0 -ne $status ]]; then
        echo "Failed to compile $project"
        exit 1
    fi
done
