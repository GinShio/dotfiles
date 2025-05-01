function set-git-urls
    argparse 'path=?' 'repo=?' page contribute -- $argv
    if not set -ql _flag_path
        set -fx _flag_path $PWD
    end
    if not set -ql _flag_repo
        set -fx _flag_repo (basename $_flag_path)
    end
    set -fx username (git config --get user.name)
    if set -ql _flag_contribute
        git -C $_flag_path remote remove contribute >/dev/null 2>&1
        set -lx upstream_url (git -C $_flag_path remote get-url origin 2>/dev/null)
        string match -rq 'https:\/\/(?<host_name>[\w.-]+)\/(?<org_name>[\w/.-]+)\/(?<repo_name>[\w.-]+\.git)' -- "$upstream_url"
        set -lx downstream_url "https://$host_name/$username/$repo_name"
        git -C $_flag_path remote add contribute $downstream_url
        return 0
    end
    git -C $_flag_path remote remove origin >/dev/null 2>&1
    if set -ql _flag_page
        git -C $_flag_path remote add origin https://codeberg.org/$username/$username.codeberg.page.git
        git -C $_flag_path remote set-url --add --push origin codeberg:$username/$username.codeberg.page.git
        git -C $_flag_path remote set-url --add --push origin github:$username/$username.github.io.git
        git -C $_flag_path remote set-url --add --push origin gitlab:$username/$username.gitlab.io.git
        git -C $_flag_path remote set-url --add --push origin bitbucket:$username/$username.bitbucket.io.git
    else if set -ql _flag_repo
        git -C $_flag_path remote add origin https://codeberg.org/$username/$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin codeberg:$username/$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin github:$username/$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin gitlab:$username/$_flag_repo.git
        git -C $_flag_path remote set-url --add --push origin bitbucket:$username/$_flag_repo.git
    end
    git -C $_flag_path --set-upstream=origin/master master >/dev/null 2>&1
    git -C $_flag_path --set-upstream=origin/main main >/dev/null 2>&1
    return 0
end
