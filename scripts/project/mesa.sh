declare -A project_info0

declare_mesa() {
    project_info0=(
        [url]='https://gitlab.freedesktop.org/mesa/mesa.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_mesa() {
    CC="ccache $C_COMPILER" CC_LD=$LINKER CXX="ccache $CXX_COMPILER" CXX_LD=$LINKER \
        meson setup $sourcedir $builddir/_rel \
        --libdir=lib --prefix $HOME/.local -Dbuildtype=release \
        -Dgallium-drivers=radeonsi,zink,llvmpipe \
        -Dvulkan-drivers=amd,swrast \
        -Dgallium-rusticl=false
    local rel_status=$?
    if [ $rel_status -ne 0 ]; then return $rel_status; fi
    CC="ccache $C_COMPILER" CC_LD=$LINKER CXX="ccache $CXX_COMPILER" CXX_LD=$LINKER \
        meson setup $sourcedir $builddir/_dbg \
        --libdir=lib --prefix $builddir/_dbg -Dbuildtype=debug \
        -Dgallium-drivers=radeonsi,zink,llvmpipe \
        -Dvulkan-drivers=amd,swrast \
        -Dgallium-rusticl=false
    return $?
    # MESA_ROOT=$HOME/.local \
    #       LD_LIBRARY_PATH=$MESA_ROOT/lib LIBGL_DRIVERS_PATH=$MESA_ROOT/lib/dri \
    #       VK_DRIVER_FILES=$(eval echo "$MESA_ROOT/share/vulkan/icd.d/{radeon,lvp}_icd.x86_64.json" |tr ' ' ':') VK_LOADER_DRIVERS_DISABLE= \
    #       OCL_ICD_FILENAMES=$MESA_ROOT/lib/libRusticlOpenCL.so RUSTICL_ENABLE=zink \
    #       MESA_SHADER_CACHE_DISABLE=true MESA_LOADER_DRIVER_OVERRIDE=radeonsi LIBGL_ALWAYS_SOFTWARE= \
    #       RADV_DEBUG=nocache RADV_PERFTEST= AMD_DEBUG= \
    #       LP_DEBUG= LP_PERF= RUSTICL_DEBUG= \
    #       ACO_DEBUG= NIR_DEBUG= \
    #       dosomething
}

build_mesa() {
    meson compile -C $builddir/_rel && meson install -C $builddir/_rel
    local rel_status=$?
    if [ $rel_status -ne 0 ]; then return $rel_status; fi
    meson compile -C $builddir/_dbg && meson install -C $builddir/_dbg
    return $?
}
