#/usr/bin/env fish

# https://github.com/ErikBjare/dotfiles/blob/master/home/.config/fish/functions/source-posix.fish

# Tries to source a bash env file line by line with fish,
# skips lines that start with '#'
function source-posix
    for i in (cat $argv)
        switch $i
            case '#*'
                #echo "comment $i skipped"
            case ''
                #echo "empty line skipped"
            case '*'
                set -f name (string split -f1 = "$i")
                set -f name_len (string length "$name")
                set -f value (string sub -s (math $name_len + 2) "$i" |xargs -I@ echo @)
                set -gx $name $value
        end
    end
end

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
