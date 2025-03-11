#/usr/bin/env fish

# Tries to unset a bash env file line by line with fish,
# skips lines that start with '#'
function desource-posix
    for i in (cat $argv)
        switch $i
            case '#*'
                #echo "comment $i skipped"
            case ''
                #echo "empty line skipped"
            case '*'
                set -f name (string split -f1 = "$i")
                set -gu $name
        end
    end
end
