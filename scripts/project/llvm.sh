declare -A project_info0

declare_llvm() {
    project_info0=(
        [url]='https://github.com/llvm/llvm-project.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/compiler/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build/_dbg
}

config_llvm() {
    cmake -S$sourcedir/llvm -B$builddir "${CMAKE_OPTIONS[@]}" \
        -DCMAKE_BUILD_TYPE=Debug -GNinja \
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
    return $?
}

build_llvm() {
    cmake --build $builddir
    return $?
}
