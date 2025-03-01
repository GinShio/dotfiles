function set-git-urls
    argparse 'path=?' 'repo=?' page -- $argv
    if not set -ql _flag_path
        set -fx _flag_path $PWD
    end
    git -C $_flag_path remote remove origin >/dev/null 2>&1
    if set -ql _flag_page
        git -C $_flag_path remote add origin codeberg:GinShio/ginshio.codeberg.page.git
        git -C $_flag_path remote set-url --add --push origin codeberg:GinShio/ginshio.codeberg.page.git
        git -C $_flag_path remote set-url --add --push origin github:GinShio/ginshio.github.io.git
        git -C $_flag_path remote set-url --add --push origin gitlab:GinShio/ginshio.gitlab.io.git
        git -C $_flag_path remote set-url --add --push origin bitbucket:GinShio/GinShio.bitbucket.io.git
    else if set -ql _flag_repo
        git -C $_flag_path remote add origin codeberg:$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin codeberg:$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin github:$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin gitlab:$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin bitbucket:$_flag_repo.git
    end
    git -C $_flag_path --set-upstream=origin/master master >/dev/null 2>&1
    git -C $_flag_path --set-upstream=origin/main main >/dev/null 2>&1
end
