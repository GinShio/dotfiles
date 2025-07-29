declare -A project_info0

declare_glslang() {
    project_info0=(
        [url]='https://github.com/KhronosGroup/glslang.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_glslang() {
    python3 update_glslang_sources.py --site github
    if [ 0 -eq $? ]; then
        cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
            -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release -DCMAKE_BUILD_TYPE=Release \
            -DENABLE_HLSL=OFF -DBUILD_TESTING=OFF -DENABLE_OPT=OFF -DINSTALL_GTEST=OFF
    fi
    return $?
}

build_glslang() {
    cmake --build $builddir --config Release
    return $?
}
