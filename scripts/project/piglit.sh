declare -A project_info0

declare_piglit() {
    project_info0=(
        [url]='https://gitlab.freedesktop.org/mesa/piglit.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_piglit() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release
    return $?
}

build_piglit() {
    cmake --build $builddir --config Release
    return $?
}
