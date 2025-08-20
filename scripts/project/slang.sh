declare -A project_info0

declare_slang() {
    project_info0=(
        [url]='https://github.com/shader-slang/slang.git'
        [branch]=master
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_slang() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
        -DSLANG_SLANG_LLVM_FLAVOR=DISABLE \
        -DSLANG_ENABLE_CUDA=OFF \
        -DSLANG_ENABLE_OPTIX=OFF \
        -DSLANG_ENABLE_DX_ON_VK=OFF \
        -DSLANG_ENABLE_DXIL=ON
    return $?
}

build_slang() {
    cmake --build $builddir --config Release
    return $?
}
