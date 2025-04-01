#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh
export DISTRO_NAME=$(source /etc/os-release; echo "${NAME:-${DISTRIB_ID}} ${VERSION_ID:-${DISTRIB_RELEASE}}")
export DISTRO_ID=$(source /etc/os-release; echo "${ID}")

TEMP=`getopt -o h --long help,swapsize:,hostname:,tidever:,working -- "$@"`
eval set -- "$TEMP"

SETUP_WORKING=0
while true; do
    case "$1" in
        -h|--help)
            shift 1;;
        --swapsize)
            SETUP_SWAPSIZE=$2
            shift 2;;
        --hostname)
            SETUP_HOSTNAME=$2
            shift 2;;
        --working)
            SETUP_WORKING=1
            shift;;
        --)
            shift 2; break;;
        *)
            echo "Internal error!"; exit 1;;
    esac
done

export SETUP_SWAPSIZE=${SETUP_SWAPSIZE:-$(echo $(( $(grep MemTotal /proc/meminfo |awk '{print $2}') / 1024 ** 2 * 2 )))}
export SETUP_HOSTNAME=${SETUP_HOSTNAME:-$([[ $SETUP_WORKING -ne 0 ]] && echo "$WORK_ORGNAIZATION-")$USER-$(echo $DISTRO_NAME |awk '{ print $1 }')}

set -o allexport
source $DOTFILES_ROOT_PATH/config.d/env
set +o allexport
if [[ $SETUP_WORKING -ne 0 ]]; then
    export WORK_ORGNAIZATION=$(tr '[:upper:]' '[:lower:]' <<<$WORK_ORGNAIZATION)
else
    export WORK_ORGNAIZATION=personal
fi

sudo -Sv <<<"$ROOT_PASSPHRASE"
if [ $? -ne 0 ]
then echo "Incorrect Password"; exit 1;
fi
case $DISTRO_NAME in
    Debian*)
        sudo bash $DOTFILES_ROOT_PATH/scripts/bringup/debian.sh
        ;;
    openSUSE*)
        sudo bash $DOTFILES_ROOT_PATH/scripts/bringup/opensuse.sh
        ;;
    *)
       echo Unknown Distro
       exit 1
       ;;
esac
sudo -Sv <<<"$ROOT_PASSPHRASE"

# user group
sudo usermod -aG kvm,libvirt,render,video $(whoami)

# applications
flatpak install flathub com.discordapp.Discord
pipx install dotdrop iree-base-compiler[onnx] pyright trash-cli

# Directories
mkdir -p $HOME/Projects
mkdir -p $HOME/.local/{bin,share,lib}
mkdir -p $HOME/.local/share/{fonts,applications}
yes |dotdrop install -c $DOTFILES_ROOT_PATH/dotfiles.yaml -p $WORK_ORGNAIZATION
yes |sudo $HOME/.local/bin/dotdrop install -c $DOTFILES_ROOT_PATH/system.yaml -p $WORK_ORGNAIZATION
bash $DOTFILES_ROOT_PATH/scripts/secret.sh -d --profile $WORK_ORGNAIZATION
yes |dotdrop install -c $DOTFILES_ROOT_PATH/secret.yaml -p $WORK_ORGNAIZATION

# swap file && runtime dir
sudo dd if=/dev/zero of=/swapfile bs=4MiB count=$(( 256*SETUP_SWAPSIZE )) status=progress
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
cat <<-EOF |sudo tee -a /etc/fstab
/swapfile                                  none       swap  defaults,pri=10  0  0
EOF

sudo sysctl -p
# Hosts
sudo cp /etc/hosts /etc/hosts.bkp
curl https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |sudo tee -a /etc/hosts
if ! [ -z $SETUP_HOSTNAME ]; then
    sudo hostnamectl set-hostname $SETUP_HOSTNAME
fi

# Service
sudo systemctl enable --now libvirtd
sudo virsh net-autostart default
sudo systemctl enable --now podman
sudo systemctl enable --now sshd.service
sudo systemctl enable --now systemd-tmpfiles-clean

# Fish
cd $(mktemp -d)
curl -o fisher.fish -SL https://github.com/jorgebucaran/fisher/raw/main/functions/fisher.fish
fish -C 'source fisher.fish' -c "fisher install jorgebucaran/fisher IlanCosman/tide PatrickF1/fzf.fish"
fish -c "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Sharp --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=No"

# Update desktop database
update-desktop-database $HOME/.local/share/applications

#bash $DOTFILES_ROOT_PATH/scripts/bringup/beautify.sh

declare -a projects=(alive2 deqp llvm mesa piglit vkd3d)
for project in ${projects[@]}; do
    bash $DOTFILES_ROOT_PATH/scripts/projects.sh --project $project --skipbuild
done
