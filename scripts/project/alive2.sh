declare -A project_info0

declare_alive2() {
    project_info0=(
        [url]='https://github.com/AliveToolkit/alive2.git'
        [branch]=master
        [sourcedir]=$HOME/Projects/compiler/$project
    )
    project_info0[builddir]=${project_info0[sourcedir]}/_build
}

config_alive2() {
    ( export ALIVE2_HOME=$HOME/Projects/compiler; \
      export LLVM2_HOME=$ALIVE2_HOME/llvm; \
      export LLVM2_BUILD=$LLVM2_HOME/_build/_dbg; \
      cmake -S$sourcedir -B$builddir -G"Ninja Multi-Config" -DCMAKE_DEFAULT_BUILD_TYPE=Release "${CMAKE_OPTIONS[@]}" -DBUILD_TV=1 -DCMAKE_PREFIX_PATH=$LLVM2_BUILD; )
    return $?
}

build_alive2() {
    cmake --build $builddir --config Release
    return $?
}
