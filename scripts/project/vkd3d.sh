declare -A project_info0

declare_vkd3d() {
    project_info0=(
        [url]='https://github.com/HansKristian-Work/vkd3d-proton.git'
        [branch]=master
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build/_rel
}

config_vkd3d() {
    CC="ccache $C_COMPILER" CC_LD=$LINKER CXX="ccache $CXX_COMPILER" CXX_LD=$LINKER \
        meson setup $sourcedir $builddir -Dbuildtype=release \
        -Denable_tests=true \
        -Denable_extras=false
    return $?
}

build_vkd3d() {
    meson compile -C $builddir
    return $?
}
