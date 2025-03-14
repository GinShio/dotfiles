#!/usr/bin/env bash

source $(dirname $0)/common.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper ref
sudo -Sv <<<$ROOT_PASSPHRASE
sudo -E zypper dup -y
bash $DOTFILES_ROOT_PATH/scripts/update-github-hosts.sh

now_timestamps=$(date +%s)

if [ -e $HOME/Projects/amdvlk ] && [ -e $HOME/Projects/Builder ]; then
    python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl monorepo
    if [ $? -eq 0 ]; then
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --release
        python3 $HOME/Projects/Builder/scripts/main.py --loglevel=info -pxgl build --debug --tool
    fi
fi
$DOTFILES_ROOT_PATH/scripts/projects.sh --project=mesa >dev/null 2>&1
$DOTFILES_ROOT_PATH/scripts/projects.sh --project=llvm --skipbuild >dev/null 2>&1

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
tmux send-keys -t runner "bash $DOTFILES_ROOT_PATH/scripts/daily.test.sh '${test_infos[*]}'" ENTER

#systemctl reboot
