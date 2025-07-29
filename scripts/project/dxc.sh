declare -A project_info0

declare_dxc() {
    project_info0=(
        [url]='https://github.com/microsoft/DirectXShaderCompiler.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_dxc() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
        -C$sourcedir/cmake/caches/PredefinedParams.cmake \
        -DENABLE_SPIRV_CODEGEN=ON \
        -DSPIRV_BUILD_TESTS=ON \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
        -DLLVM_PARALLEL_LINK_JOBS:STRING=$llvm_num_link
    return $?
}

build_dxc() {
    cmake --build $builddir --config Release
    return $?
}
