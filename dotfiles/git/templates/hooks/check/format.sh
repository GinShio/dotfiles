#!/usr/bin/env bash

if ! [ -e $GIT_TOPLEVEL_DIR/.clang-format ]; then
    exit 0
fi

count=0
for ctx in `git diff --cached --name-only --diff-filter=ACM |git check-attr --stdin text |tr -d ' '`; do
    IFS=':' read file attr info <<< "$ctx"
    if ! [ -f "$file" ] || [ "$info" = "unset" ]; then
        continue
    fi
    case "${file##*.}" in
        c|h|inc)           ;& # C files
        hh|hpp|hxx|h\+\+)  ;& # C++ header files
        cc|cpp|cxx|c\+\+)  ;& # C++ source files
        icc|ipp|ixx|i\+\+) ;& # C++ macro / template files
        tcc|tpp|txx|t\+\+)    # C++ template files
            clang-format --Wno-error=unknown -i "$file"
            ;;
        *)
            sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' -e 's/[[:space:]]*$//' "$file"
            ;;
    esac
    status=$?
    if [ $status -ne 0 ]; then
        : $(( count++ ))
        echo >&2 "$file: failed to format"
    else
        git add "$file"
    fi
done
exit $count
