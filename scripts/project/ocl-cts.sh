declare -A project_info0
declare -A project_info1
declare -A project_info2

declare_ocl-cts() {
    C_COMPILER=gcc
    CXX_COMPILER=g++
    LINKER=gold
    project_info0=(
        [url]='https://github.com/KhronosGroup/OpenCL-Headers.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/ocl-headers
    )
    project_info1=(
        [url]='https://github.com/KhronosGroup/OpenCL-ICD-Loader.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/ocl-icd
    )
    project_info1[builddir]=${project_info1[sourcedir]}/_build
    project_info2=(
        [url]='https://github.com/KhronosGroup/OpenCL-CTS.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info2[builddir]=${project_info2[sourcedir]}/_build/_rel
}

config_ocl-cts() {
    if [ "$project" = $(basename $sourcedir) ]; then
        cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
            -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
            -DCL_INCLUDE_DIR=$sourcedir/../ocl-headers \
            -DCL_LIB_DIR=$sourcedir/../ocl-icd/_build \
            -DOPENCL_LIBRARIES=OpenCL
    else
        cmake -S$sourcedir -B$builddir "${CMAKE_OPTIONS[@]}" \
            -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release \
            -DOPENCL_ICD_LOADER_HEADERS_DIR=$sourcedir/../ocl-headers
    fi
    return $?
}

build_ocl-cts() {
    cmake --build $builddir
    return $?
}
