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
                set arr (echo $i |tr = \n)
                set -gx $arr[1] $arr[2]
        end
    end
end
