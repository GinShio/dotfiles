#!/usr/bin/env bash

# git config --local hooks.clangformat.enabled 1
ENABLE=$(git config --get hooks.clangformat.enabled)
if [ -z $ENABLE ] || [ $ENABLE -eq 0 ]; then
    exit
fi
find-program clang-format
# git config --local hooks.clangformat.style llvm
STYLE=$(git config --get hooks.clangformat.style)
STYLEARG=""
if [ -e $GIT_TOPLEVEL_DIR/.clang-format ]; then
    :
elif [ -n "${STYLE}" ] ; then
    STYLEARG="-style=${STYLE}"
else
    exit
fi

function clang-format-formatting() {
    local file="$1"
    case "${file##*.}" in
        c|h|inc)           ;& # C files
        hh|hpp|hxx|h\+\+)  ;& # C++ header files
        cc|cpp|cxx|c\+\+)  ;& # C++ source files
        icc|ipp|ixx|i\+\+) ;& # C++ macro / template files
        tcc|tpp|txx|t\+\+)    # C++ template files
            clang-format --Wno-error=unknown $STYLEARG -i "$file"
            ;;
        *) ;;
    esac
    return 0
}

count=0
for ctx in `git diff --cached --name-only --diff-filter=ACM |git check-attr --stdin text |tr -d ' '`; do
    IFS=':' read file attr info <<< "$ctx"
    if ! [ -f "$file" ] || [ "$info" = "unset" ]; then
        continue
    fi
    clang-format-formatting "$file" && sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' -e 's/[[:space:]]*$//' "$file"
    status=$?
    if [ $status -ne 0 ]; then
        : $(( count++ ))
        echo >&2 "$file: failed to format"
    else
        git add "$file"
    fi
done
exit $count
