declare -A project_info0

declare_vulkan-samples() {
    project_info0=(
        [url]='https://github.com/KhronosGroup/Vulkan-Samples.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_vulkan-samples() {
    cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
        -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
        -DVKB_VALIDATION_LAYERS=ON \
        -DVKB_WSI_SELECTION=WAYLAND
    return $?
}

build_vulkan-samples() {
    cmake --build $builddir --config Release
    return $?
}
