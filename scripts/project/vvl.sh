declare -A project_info0

declare_vvl() {
    project_info0=(
        [url]='https://github.com/KhronosGroup/Vulkan-ValidationLayers.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_vvl() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$HOME/.local \
        -DUPDATE_DEPS=ON \
        -DBUILD_WERROR=ON \
        -DBUILD_TESTS=ON \
        -DBUILD_WSI_XCB_SUPPORT=OFF \
        -DBUILD_WSI_XLIB_SUPPORT=OFF \
        -DBUILD_WSI_WAYLAND_SUPPORT=ON
    return $?
}

build_vvl() {
    cmake --build $builddir --config Release
    return $?
}
