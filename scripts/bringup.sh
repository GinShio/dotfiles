#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/common/common.sh
export SUDO_ASKPASS=$(dirname ${BASH_SOURCE[0]})/common/get-root-passphrase.sh
export DISTRO_NAME=$(source /etc/os-release; echo "${NAME:-${DISTRIB_ID}} ${VERSION_ID:-${DISTRIB_RELEASE}}")
export DISTRO_ID=$(source /etc/os-release; echo "${ID}")
trap "sudo -k" EXIT

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

export SETUP_SWAPSIZE=${SETUP_SWAPSIZE:-$(awk '/MemTotal/{print int($2 / 2^20 * 2)}' /proc/meminfo)}
export SETUP_HOSTNAME=${SETUP_HOSTNAME:-$([[ $SETUP_WORKING -ne 0 ]] && echo "$WORK_ORGNAIZATION-")$USER-$(awk '{ print $1 }' <<<"$DISTRO_NAME")}

if [[ $SETUP_WORKING -ne 0 ]]; then
    export WORK_ORGNAIZATION=$(tr '[:upper:]' '[:lower:]' <<<$WORK_ORGNAIZATION)
else
    export WORK_ORGNAIZATION=personal
fi

if [ $? -ne 0 ]
then echo "Incorrect Password"; exit 1;
fi
case $DISTRO_NAME in
    Debian*)
        sudo -A -- bash $DOTFILES_ROOT_PATH/scripts/bringup/debian.sh
        ;;
    openSUSE*)
        sudo -A -- bash $DOTFILES_ROOT_PATH/scripts/bringup/opensuse.sh
        ;;
    *)
       echo Unknown Distro
       exit 1
       ;;
esac

# user group
sudo -AE -- usermod -aG kvm,libvirt,render,video $(whoami)

# applications
flatpak install flathub com.discordapp.Discord
pipx install dotdrop iree-base-compiler[onnx] pyright trash-cli

# Directories
mkdir -p $HOME/Projects
mkdir -p $HOME/.local/{bin,share,lib}
mkdir -p $HOME/.local/share/{fonts,applications}
yes |dotdrop install -c $DOTFILES_ROOT_PATH/dotfiles.yaml -p $WORK_ORGNAIZATION
yes |sudo -A -- $HOME/.local/bin/dotdrop install -c $DOTFILES_ROOT_PATH/system.yaml -p $WORK_ORGNAIZATION
bash $DOTFILES_ROOT_PATH/scripts/secret.sh -d --profile $WORK_ORGNAIZATION
yes |dotdrop install -c $DOTFILES_ROOT_PATH/secret.yaml -p $WORK_ORGNAIZATION

# swap file && runtime dir
sudo -A -- dd if=/dev/zero of=/swapfile bs=4MiB count=$(( 256*SETUP_SWAPSIZE )) status=progress
sudo -A -- chmod 0600 /swapfile
sudo -A -- mkswap /swapfile
sudo -A -- swapon /swapfile
cat <<-EOF |sudo -A -- tee -a /etc/fstab
/swapfile                                  none       swap  defaults,pri=10  0  0
EOF

sudo -A -- sysctl -p
# Hosts
# sudo -A -- cp /etc/hosts /etc/hosts.bkp
# curl https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |sudo -A -- tee -a /etc/hosts
if ! [ -z $SETUP_HOSTNAME ]; then
    sudo -A -- hostnamectl set-hostname $SETUP_HOSTNAME
fi

# Service
sudo -A -- systemctl daemon-reload
sudo -A -- systemctl enable --now libvirtd
sudo -A -- virsh net-autostart default
sudo -A -- systemctl enable --now podman
sudo -A -- systemctl enable --now sshd.service
sudo -A -- systemctl enable --now systemd-tmpfiles-clean

systemctl enable --user --now nightly-script.timer
systemctl enable --user --now emacs.service
systemctl enable --user develop-autostart.service

# Fish
cd $(mktemp -d)
curl -o fisher.fish -SL https://github.com/jorgebucaran/fisher/raw/main/functions/fisher.fish
fish -C 'source fisher.fish' -c "fisher install jorgebucaran/fisher IlanCosman/tide PatrickF1/fzf.fish"
fish -c "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Sharp --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=No"

# Update desktop database
update-desktop-database $HOME/.local/share/applications

loginctl enable-linger $(whoami)

#bash $DOTFILES_ROOT_PATH/scripts/bringup/beautify.sh
