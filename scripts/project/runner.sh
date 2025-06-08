declare -A project_info0

declare_runner() {
    project_info0=(
        [url]='https://gitlab.freedesktop.org/mesa/deqp-runner.git'
        [branch]=main
        [sourcedir]=$HOME/Projects/khronos3d/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_runner() {
    cargo build --release --target-dir $builddir
    return $?
}

build_runner() {
    cargo build --release --target-dir $builddir
    return $?
}
