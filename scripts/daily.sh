#!/usr/bin/env bash

set -o allexport
source $HOME/dotfiles/.env
set +o allexport
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper ref
sudo -E zypper dup -y
sudo cp /etc/hosts.bkp /etc/hosts
sudo bash -c "curl -s https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |tee -a /etc/hosts"

export PATH=$HOME/.local/bin:$PATH

now_timestamps=$(date +%s)

$HOME/dotfiles/scripts/projects.sh --project=mesa >dev/null 2>&1
$HOME/dotfiles/scripts/projects.sh --project=llvm --skipbuild >dev/null 2>&1

fd -iHx /usr/bin/rm -rf {} \; --changed-before 3d --type directory -- . "/run/user/$(id -u $USER)/runner/baseline"

# Testing only on Monday or Thursday
{ date +%A |grep -qi -e Monday -e Thursday; } || exit 0

drivers_tuple=(
    # vendor,glapi,kits,driver
    #llpc,vk,"deqp",$AMDVLK_PATH
    mesa,vk,"deqp",$RADV_PATH
    #llpc,zink,"deqp",$AMDVLK_PATH
    mesa,zink,"deqp",$RADV_PATH
    #mesa,gl,"deqp:piglit",$RADEONSI_PATH
) # drivers tuple declare end

declare -a test_infos=()
for elem in ${drivers_tuple[@]}; do
    IFS=',' read vendor glapi testkits driver <<< "${elem}"
    if ! [ -e $driver ] || [ $now_timestamps -ge $(stat -c "%Y" "$driver") ]; then
        continue
    fi
    test_infos+=("$vendor,$glapi,$testkits")
done
tmux send-keys -t runner "bash $HOME/dotfiles/scripts/daily.test.sh '${test_infos[*]}'" ENTER

#systemctl reboot
