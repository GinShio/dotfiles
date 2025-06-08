declare -A project_info0

declare_slang() {
    project_info0=(
        [url]='https://github.com/shader-slang/slang.git'
        [branch]=master
        [sourcedir]=$HOME/Projects/compiler/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_slang() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
        -DSLANG_SLANG_LLVM_FLAVOR=DISABLE
    return $?
}

build_slang() {
    cmake --build $builddir --config Release
    return $?
}
