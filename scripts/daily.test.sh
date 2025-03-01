#!/usr/bin/env bash

export XDG_RUNTIME_DIR=/run/user/$(id -u $USER)
RUNNER_DIR=$XDG_RUNTIME_DIR/runner
set -o allexport
source $HOME/dotfiles/.driver.env
set +o allexport

SUFFIX=_$(date "+%Y-%m-%d")
DEVICE_ID=$(vulkaninfo 2>/dev/null |awk '/deviceID[[:blank:]]*=/ {print $NF; exit}')
AVAILABLE_CPUS_CNT=$(cnt=$(bc <<<"($(lscpu -e |wc -l) - 1) * 0.75 / 1"); echo $(($cnt > 0 ? $cnt : 1)))

function get_repo_sha1() {
    touch git-sha1.txt
    if [ "$glapi" = "zink" ] || [ "$vendor" = "mesa" ]
    then echo " + mesa: $(git -C $HOME/Projects/mesa rev-parse --short=11 HEAD)" >>git-sha1.txt
    fi
    echo " + $testkit: $(git -C $HOME/Projects/$testkit rev-parse --short=11 HEAD)" >>git-sha1.txt
}

function test_kits_deqp() {
    deqp_options='--deqp-log-images=disable --deqp-log-shader-sources=disable --deqp-log-decompiled-spirv=disable --deqp-shadercache=disable'
    result_files=(
        flakes.txt
        git-sha1.txt
        testlist.txt
    )
    case $glapi in
        vk)
            exe_name=deqp-vk
            case_lists=(
                $RUNNER_DIR/deqp/mustpass/vk-default/{binding-model,descriptor-indexing}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/{image/*,robustness,sparse-resources,ssbo,texture,ubo}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/compute.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/tessellation.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/geometry.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/{clipping,transform-feedback}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/mesh-shader.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/{depth,fragment-*}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/{ray-tracing-pipeline,ray-query}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/pipeline/*.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/{conditional-rendering,dynamic-rendering,renderpass{,2}}.txt
                $RUNNER_DIR/deqp/mustpass/vk-default/{reconvergence,subgroups}.txt
                #$RUNNER_DIR/deqp/mustpass/vk-default/dgc.txt
            )
            ext_files=(dEQP-VK.info.device)
            runner_options=(
                "--jobs $AVAILABLE_CPUS_CNT"
                "--tests-per-group 4096"
                "--timeout 300.0"
            )
            ext_deqp_options=()
            ;;
        gl|zink)
            exe_name=glcts
            case_lists=(
                #$RUNNER_DIR/deqp/mustpass/{egl,gl,gles}/aosp_mustpass/main/*-main.txt
                $RUNNER_DIR/deqp/mustpass/gl{,es}/khronos_mustpass/main/*-main.txt
                $RUNNER_DIR/deqp/mustpass/gl/khronos_mustpass_single/main/*-single.txt
            )
            ext_files=()
            runner_options=(
                "--jobs $AVAILABLE_CPUS_CNT"
                "--timeout 300.0"
            )
            ext_deqp_options=(
                --deqp-gl-config-name=rgba8888d24s8ms0
                --deqp-surface-{height,width}=256
                --deqp-visibility=hidden
            )
            ;;
        *)
            exit -1
            ;;
    esac
    $RUNNER_DIR/deqp-runner run \
        ${runner_options[@]} \
        --deqp $RUNNER_DIR/$testkit/$exe_name \
        --output $output_dir \
        --caselist ${case_lists[@]} \
        --env ${env_lists[@]} \
        -- \
        $deqp_options ${ext_deqp_options[@]}
    cd $output_dir
    get_repo_sha1
    ls -1 ${case_lists[@]} |sed "s~$RUNNER_DIR/$testkit/mustpass/~~g" >testlist.txt
    awk -F, '$2 == "Flake"{print $1}' results.csv >flakes.txt
    tar -H pax -cf - {failures,results}.csv $(eval echo ${result_files[@]}) ${ext_files[@]} | \
        zstd -z -19 --ultra --quiet -o ${tarball_name}.tar.zst
} # test_kits_deqp function end

function test_kits_piglit() {
    runner_options=(
        "--jobs $AVAILABLE_CPUS_CNT"
        "--timeout 300"
    )
    result_files=(
        flakes.txt
        git-sha1.txt
    )
    $RUNNER_DIR/piglit-runner run \
        ${runner_options[@]} \
        --piglit-folder $RUNNER_DIR/piglit \
        --output $output_dir \
        --env ${env_lists[@]} \
        --profile quick \
        -- \

    cd $output_dir
    get_repo_sha1
    awk -F, '$2 == "Flake"{print $1}' results.csv >flakes.txt
    tar -H pax -cf - {failures,results}.csv $(eval echo ${result_files[@]}) | \
        zstd -z -19 --ultra --quiet -o ${tarball_name}.tar.zst
} # test_kits_piglit function end

function test_kits_vkd3d() {
    declare -x ${env_lists[@]}
    VKD3D_SHADER_CACHE_PATH=0 \
    bash $RUNNER_DIR/vkd3d/tests/test-runner.sh \
        --output-dir $output_dir \
        --jobs $AVAILABLE_CPUS_CNT \
        $RUNNER_DIR/vkd3d/bin/d3d12 >$output_dir-results.txt
    cd $output_dir
    get_repo_sha1
    mv $output_dir-results.txt results.txt
    tar -H pax -cf - results.txt git-sha1.txt *.log | \
        zstd -z -19 --ultra --quiet -o ${tarball_name}.tar.zst
} # test_kits_vkd3d function end

declare -a test_infos=$1
for elem in ${test_infos[@]}; do
    IFS=',' read vendor glapi testkits <<< "${elem}"
    case $vendor in
        mesa)
            env_lists=(
                VK_ICD_FILENAMES=$RADV_ICD_PATH
                __GLX_FORCE_VENDOR_LIBRARY_0=mesa
                LD_LIBRARY_PATH=$MESA_ROOT
                LIBGL_DRIVERS_PATH=$MESA_ROOT/dri
                MESA_LOADER_DRIVER_OVERRIDE=radeonsi
                RADV_DEBUG=nocache
                AMD_DEBUG=
                NIR_DEBUG=
            )
            ;;
        llpc)
            env_lists=(
                VK_ICD_FILENAMES=$AMDVLK_ICD_PATH
            )
            ;;
        *)
            exit -1
            ;;
    esac
    case $glapi in
        zink)
            env_lists+=(
                __GLX_FORCE_VENDOR_LIBRARY_0=mesa
                LD_LIBRARY_PATH=$MESA_ROOT
                LIBGL_DRIVERS_PATH=$MESA_ROOT/dri
                MESA_LOADER_DRIVER_OVERRIDE=zink
            )
            ;;
        *)
            ;;
    esac
    for testkit in $(tr ':' '\t' <<<$testkits); do
        tarball_name=${testkit}-${glapi}_${DEVICE_ID}${SUFFIX}
        output_dir=$RUNNER_DIR/baseline/${vendor}_${testkit}-${glapi}${SUFFIX}
        test_kits_$testkit
    done # test kits loop end
done # test infos loop end
