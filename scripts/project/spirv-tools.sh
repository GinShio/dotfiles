declare -A project_info0

declare_spirv-tools() {
    project_info0=(
        [url]='https://github.com/KhronosGroup/SPIRV-Tools.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_spirv-tools() {
    python3 utils/git-sync-deps --treeless
    if [ 0 -eq $? ]; then
        cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
            -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
            -DSPIRV_COLOR_TERMINAL=ON \
            -DSPIRV_BUILD_FUZZER=ON
    fi
    return $?
}

build_spirv-tools() {
    cmake --build $builddir --config Release
    return $?
}
