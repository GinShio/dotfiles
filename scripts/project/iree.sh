declare -A project_info0
declare -A project_info1

declare_iree() {
    project_info0=(
        [url]='https://github.com/iree-org/iree.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/compiler/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build/_dbg
    project_info1=(
        [url]='https://github.com/onnx/models.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/AI/onnx-models
    )
}

config_iree() {
    # if wants to use the trunk llvm, please use: CMAKE_PREFIX_PATH=$HOME/Projects/llvm/_build/_dbg/lib/cmake
    cmake -S$sourcedir -B$builddir -DCMAKE_INSTALL_PREFIX=$sourcedir/_install "${CMAKE_OPTIONS[@]}" \
        -DCMAKE_BUILD_TYPE=Debug -GNinja \
        -DIREE_BUILD_COMPILER=ON \
        -DIREE_BUILD_TESTS=ON \
        -DIREE_BUILD_SAMPLES=ON \
        -DIREE_BUILD_PYTHON_BINDINGS=OFF \
        -DIREE_BUILD_BINDINGS_TFLITE=OFF \
        -DIREE_BUILD_BINDINGS_TFLITE_JAVA=OFF \
        -DIREE_TARGET_BACKEND_DEFAULTS=OFF \
        -DIREE_TARGET_BACKEND_LLVM_CPU=ON \
        -DIREE_TARGET_BACKEND_VULKAN_SPIRV=ON \
        -DIREE_HAL_DRIVER_DEFAULTS=OFF \
        -DIREE_HAL_DRIVER_LOCAL_SYNC=ON \
        -DIREE_HAL_DRIVER_LOCAL_TASK=ON \
        -DIREE_HAL_DRIVER_VULKAN=ON \
        -DIREE_INPUT_STABLEHLO=ON \
        -DIREE_INPUT_TORCH=ON \
        -DIREE_INPUT_TOSA=ON \
        -DIREE_BUILD_BUNDLED_LLVM=ON \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
        -DLLVM_PARALLEL_LINK_JOBS:STRING=$llvm_num_link
    return $?
}

build_iree() {
    cmake --build $builddir
    return $?
}
