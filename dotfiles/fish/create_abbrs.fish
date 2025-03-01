alias clear "clear && echo -en \"\e[3J\""
alias ping "ping -c 8"
alias condaenv "source $HOME/.local/share/anaconda3/etc/fish/conf.d/conda.fish"
alias proxy "set -xg no_proxy \"localhost,127.0.0.1,localaddress,.localdomain.com,.cn\"; set -xg http_proxy  \"http://localhost:8118\"; set -xg https_proxy \"http://localhost:8118\""
alias unproxy "set -e no_proxy; set -e http_proxy; set -e https_proxy"
#alias oneko=" oneko -fg brown -bg white -speed 16 -idle 100"
#alias uuid=" cat /proc/sys/kernel/random/uuid"
if type -q fdfind; and not type -q fd
    alias fd "fdfind"
end
if type -q batcat; and not type -q bat
    alias bat "batcat"
end

# package management
#   - repository management
#     - ar         addrepo                  添加源
#     - lr         repos                    列出源
#     - ref        refresh                  刷新源
#     - rr         removerepo               移除源
#     - mr         modifyrepo               调整源
#     - nr         renamerepo               重命名源
#   - package management
#     - arm        autoremove               自动移除
#     - in         install                  安装
#     - rm         remove                   移除
#     - si         source-install           源码包安装
#   - update management
#     - dup        dist-upgrade             发行版升级
#     - lu         list-updates             列出需升级的包
#     - up         update                   更新
#   - querying
#     - if         info                     获取包信息
#     - se         search                   查询
#     - wp         what-provides            提供的包
#     - log                                 历史记录
#   - locking
#     - al         addlock                  锁定
#     - ll         locks                    列出锁定
#     - rl         removelock               移除锁定
#     - cl         cleanlocks               ???
#   - utilities
#     - cln        clean                    清除本地缓存
#     - inr        install-new-recommends   安装新的推荐
#     - ps         check-process            检测最近修改但仍在运行的程序
#     - ve         verify                   验证依赖
switch (/bin/bash -c ". /etc/os-release; echo \"\${NAME:-\${DISTRIB_ID}} \${VERSION_ID:-\${DISTRIB_RELEASE}}\"")
    # case 'FreeBSD*'
    #    __ginshio_freebsd_package_management
    # case 'CentOS*' 'Fedora*' 'Oracle*' 'openEuler*'
    #    __ginshio_dnf_package_management
    case 'Debian*' 'Ubuntu*' 'Kali*' 'Deepin*'
        # repository management
        abbr -a Par  "sudo add-apt-repository"
        abbr -a Plr  "add-apt-repository --list"
        abbr -a Pref "sudo -E apt update"
        abbr -a Prr  "sudo add-apt-repository --remove"
        abbr -a Pmr  "sudo apt edit-sources"
        abbr -a Pnr  "sudo apt edit-sources"
        # package management
        abbr -a Parm "sudo apt autoremove --purge"
        abbr -a Pin  "sudo -E apt install"
        abbr -a Prm  "sudo apt purge"
        abbr -a Psi  "sudo -E apt-src install"
        # update management
        abbr -a Pdup "sudo -E apt dist-upgrade"
        abbr -a Plu  "apt list --upgradable"
        abbr -a Pup  "sudo -E apt upgrade"
        # querying
        abbr -a Pif  "apt show"
        #alias Pif="dpkg -s"
        abbr -a Pse  "apt search"
        abbr -a Pwp  "dpkg -s"
        #alias Pwp="dpkg -s"
        # locking
        abbr -a Pal  "sudo apt-mark hold"
        abbr -a Pll  "apt-mark showhold"
        abbr -a Prl  "sudo apt-mark unhold"
        #abbr -a Pcl  ""
        # utilities
        abbr -a Pcc  "sudo apt clean"
        abbr -a Pinr ""
        abbr -a Pps  ""
        abbr -a Pve  "sudo -E apt check"
    case 'openSUSE*'
        # repository management
        abbr -a Par  "sudo zypper addrepo -fcg"
        abbr -a Plr  "zypper repos -Np"
        abbr -a Pref "sudo -E zypper refresh"
        abbr -a Prr  "sudo zypper removerepo"
        abbr -a Pmr  "sudo zypper modifyrepo"
        abbr -a Pnr  "sudo zypper renamerepo"
        # package management
        abbr -a Parm ""
        abbr -a Pin  "sudo -E zypper install"
        abbr -a Prm  "sudo zypper remove -u"
        abbr -a Psi  "sudo -E zypper source-install"
        # update management
        abbr -a Pdup "sudo -E zypper dist-upgrade"
        abbr -a Plu  "zypper list-updates"
        abbr -a Pup  "sudo -E zypper update"
        # querying
        abbr -a Pif  "zypper info"
        #alias Pif="rpm -qi"
        abbr -a Pse  "zypper search"
        abbr -a Pwp  "zypper search --provides"
        #alias Pwp="rpm -q --whatprovides"
        abbr -a Plog "sudo cut -d \"|\" -f 1-4 -s --output-delimiter \" | \" /var/log/zypp/history"
        # locking
        abbr -a Pal  "sudo zypper addlock"
        abbr -a Pll  "zypper locks"
        abbr -a Prl  "sudo zypper removelock"
        abbr -a Pcl  "sudo zypper cleanlocks"
        # utilities
        abbr -a Pcln "sudo zypper clean"
        abbr -a Pinr "sudo -E zypper install-new-recommends"
        abbr -a Pps  "zypper ps"
        abbr -a Pve  "sudo -E zypper verify"
    case '*'
        echo "unknown $distro"
        exit 1
end
