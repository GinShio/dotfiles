declare -A project_info0

declare_deqp() {
    project_info0=(
        [url]='https://github.com/KhronosGroup/VK-GL-CTS.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_deqp() {
    python3 external/fetch_sources.py
    if [ 0 -eq $? ]; then
        cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
            -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release -DCMAKE_BUILD_TYPE=Release \
            -DDEQP_TARGET=default
    fi
    return $?
}

build_deqp() {
    cmake --build $builddir --config Release
    return $?
}
