function copy-graphics-testcase
    argparse deqp piglit tool vkd3d -- $argv
    or return
    set -fx PROJECT_DIR $HOME/Projects
    set -fx RUNNER_DIR {{@@ testing.runner_dir @@}}

    if set -ql _flag_deqp
        and test -e $PROJECT_DIR/khronos/deqp
        set -lx DEQP_SRCDIR $PROJECT_DIR/khronos/deqp
        set -lx DEQP_DSTDIR $RUNNER_DIR/deqp
        set -lx DEQP_EXCLUDE $DEQP_DSTDIR/vk-exclude.txt
        if not test -e $DEQP_EXCLUDE
            echo "api.txt
image/swapchain-mutable.txt
info.txt
query-pool.txt
video.txt
wsi.txt" >$DEQP_EXCLUDE
        end
        rsync $DEQP_SRCDIR/_build/main/external/vulkancts/modules/vulkan/Release/deqp-vk $DEQP_DSTDIR
        rsync -rR $DEQP_SRCDIR/external/vulkancts/data/./vulkan $DEQP_DSTDIR
        rsync -rR --exclude-from=$DEQP_DSTDIR/vk-exclude.txt $DEQP_SRCDIR/external/vulkancts/mustpass/main/./vk-default $DEQP_DSTDIR/mustpass
        rsync $DEQP_SRCDIR/_build/main/external/openglcts/modules/Release/glcts $DEQP_DSTDIR
        rsync -rR $DEQP_SRCDIR/_build/main/external/openglcts/modules/./gles{2,3,31}/{data,shaders} $DEQP_DSTDIR
        rsync -rR $DEQP_SRCDIR/external/graphicsfuzz/data/./gles3/graphicsfuzz/ $DEQP_DSTDIR
        rsync -rR --exclude='mustpass' $DEQP_SRCDIR/external/openglcts/data/./gl_cts $DEQP_DSTDIR
        rsync -rR --exclude='src' -f'- *-gtf-main.txt' $DEQP_SRCDIR/external/openglcts/data/gl_cts/data/mustpass/./gl/khronos_mustpass{,_single}/main/*.txt $DEQP_DSTDIR/mustpass
        rsync -rR --exclude='src' $DEQP_SRCDIR/external/openglcts/data/gl_cts/data/mustpass/./{egl,gles}/*_mustpass/main/*.txt $DEQP_DSTDIR/mustpass
        rsync -rR $DEQP_SRCDIR/external/openglcts/data/gl_cts/data/mustpass/./waivers $DEQP_DSTDIR/mustpass
        fd --regex '.*\.txt' -- $DEQP_DSTDIR/mustpass/vk-default |sed -e "s~^$DEQP_DSTDIR/mustpass/~~" >$DEQP_DSTDIR/mustpass/vk-default.txt
    end

    if set -ql _flag_piglit
        and test -e $PROJECT_DIR/fd.o/piglit
        set -lx PIGLIT_SRCDIR $PROJECT_DIR/fd.o/piglit
        set -lx PIGLIT_DSTDIR $RUNNER_DIR/piglit
        rsync -rR $PIGLIT_SRCDIR/_build/main/./bin $PIGLIT_DSTDIR
        rsync -l $PIGLIT_SRCDIR/_build/main/lib/Release/* $PIGLIT_DSTDIR/lib
        rsync -rR $PIGLIT_SRCDIR/./{framework,templates} $PIGLIT_DSTDIR
        rsync -rR $PIGLIT_SRCDIR/_build/main/./tests/*.xml.gz $PIGLIT_DSTDIR
        rsync -mrR -f'- *.[chao]' -f'- *.[ch]pp' -f'- *[Cc][Mm]ake*' $PIGLIT_SRCDIR/./tests $PIGLIT_DSTDIR
        rsync -rR $PIGLIT_SRCDIR/./generated_tests/**/*.inc $PIGLIT_DSTDIR
        rsync -mrR -f'- *.[chao]' -f'- *.[ch]pp' -f'- *[Cc][Mm]ake*' -f'- *.list' $PIGLIT_SRCDIR/_build/main/./generated_tests $PIGLIT_DSTDIR
        for elf in $PIGLIT_DSTDIR/bin/* $PIGLIT_DSTDIR/lib/*.so
            patchelf --set-rpath "$PIGLIT_DSTDIR/lib" $elf
        end
    end

    if set -ql _flag_tool
        and test -e $PROJECT_DIR/fd.o/runner
        rsync $PROJECT_DIR/fd.o/runner/_build/main/release/{deqp,piglit}-runner $RUNNER_DIR
    end

    if set -ql _flag_vkd3d
        and test -e $PROJECT_DIR/vkd3d
        set -lx VKD3D_SRCDIR $PROJECT_DIR/vkd3d
        set -lx VKD3D_DSTDIR $RUNNER_DIR/vkd3d
        rsync -f'- */' -f'- *.a' $VKD3D_SRCDIR/_build/_rel/tests/* $VKD3D_DSTDIR/bin
        rsync -rR $VKD3D_SRCDIR/tests/./{d3d12_tests.h,test-runner.sh} $VKD3D_DSTDIR/tests
        rsync -rR $VKD3D_SRCDIR/_build/_rel/./libs/**/*.so $VKD3D_DSTDIR
    end
end
