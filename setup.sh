#!/bin/bash

if [ "$(id -u)" = 0 ]; then
    echo "######################################################################"
    echo "This script should NOT be run as root user as it may create unexpected"
    echo " problems and you may have to reinstall Arch. So run this script as a"
    echo "  normal user. You will be asked for a sudo password when necessary"
    echo "######################################################################"
    exit 1
fi

read -p "Enter your Full Name: " fn
if [ -n "$fn" ]; then
    sudo chfn -f "$fn" "$(whoami)"
else
    true
fi

grep -qF "Include = /etc/pacman.d/custom" /etc/pacman.conf || echo "Include = /etc/pacman.d/custom" | sudo tee -a /etc/pacman.conf > /dev/null
echo -e "[options]\nColor\nParallelDownloads = 5\nILoveCandy\n" | sudo tee /etc/pacman.d/custom > /dev/null
sudo mkdir -p /etc/pacman.d/hooks/
sudo cp gutenprint.hook /etc/pacman.d/hooks/
sudo cp 30-touchpad.conf /etc/X11/xorg.conf.d/

echo ""
read -r -p "Do you want to install Reflector? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm reflector
    echo -e "\nIt will take time to fetch the server/mirrors so please wait"
    sudo reflector --save /etc/pacman.d/mirrorlist -p https -c 'Netherlands,United States, ' -l 10 --sort rate
    #Change location as per your need
fi

echo ""
sudo pacman -Syu --needed --noconfirm pacman-contrib
if [ "$(pactree -r linux)" ]; then
    sudo pacman -S --needed --noconfirm linux-headers
fi

if [ "$(pactree -r linux-zen)" ]; then
    sudo pacman -S --needed --noconfirm linux-zen-headers
fi

echo ""
read -r -p "Do you want to install Intel drivers? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm libva-intel-driver intel-media-driver vulkan-intel
fi

echo ""
read -r -p "Do you want to install AMD drivers? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm xf86-video-amdgpu libva-mesa-driver vulkan-radeon
fi

echo ""
read -r -p "Do you want to install Nvidia drivers(Maxwell+)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime opencl-nvidia switcheroo-control
    echo -e options "nvidia-drm modeset=1 fbdev=1\noptions nvidia NVreg_UsePageAttributeTable=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
    sudo sed -i 's/MODULES=\(.*\)/MODULES=\(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
    sudo systemctl enable nvidia-persistenced nvidia-hibernate nvidia-resume nvidia-suspend switcheroo-control

    echo ""
    read -r -p "Do you want to enable Nvidia's Dynamic Boost(Ampere+)? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo systemctl enable nvidia-powerd
    fi
fi

echo ""
sudo pacman -S --needed --noconfirm - <tpkg
sudo systemctl enable --now ufw
sudo systemctl enable --now cups
sudo systemctl disable systemd-resolved.service
sudo systemctl enable sshd avahi-daemon power-profiles-daemon
echo -e "[global]\nworkgroup = WORKGROUP\nserver string = Samba Server\nnetbios name = $(hostname)\n\n" | sudo tee /etc/samba/smb.conf > /dev/null
echo ""
sudo smbpasswd -a $(whoami)
echo ""
sudo systemctl enable smb nmb
sudo cupsctl
sudo ufw enable
sudo ufw allow IPP
sudo ufw allow CIFS
sudo ufw allow SSH
sudo cp /usr/share/doc/avahi/ssh.service /etc/avahi/services/
sudo chsh -s /usr/bin/fish $(whoami)
sudo chsh -s /usr/bin/fish
pipx ensurepath
echo -e "127.0.0.1\tlocalhost\n127.0.1.1\t$(hostname)\n\n# The following lines are desirable for IPv6 capable hosts\n::1     localhost ip6-localhost ip6-loopback\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters" | sudo tee /etc/hosts > /dev/null
#register-python-argcomplete --shell fish pipx >~/.config/fish/completions/pipx.fish

echo ""
read -r -p "Do you want to create a Samba Shared folder? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "[global]\nworkgroup = WORKGROUP\nserver string = Samba Server\nnetbios name = $(hostname)\n\n" | sudo tee /etc/samba/smb.conf > /dev/null
    echo -e "[Samba Share]\ncomment = Samba Share\npath = /home/$(whoami)/Samba Share\nwritable = yes\nbrowsable = yes\nguest ok = no" | sudo tee -a /etc/samba/smb.conf > /dev/null
    rm -rf ~/Samba\ Share
    mkdir ~/Samba\ Share
    sudo systemctl restart smb nmb
fi

#sudo sed -i 's/Logo=1/Logo=0/' /etc/libreoffice/sofficerc
echo -e "VISUAL=nvim\nEDITOR=nvim" | sudo tee /etc/environment > /dev/null
grep -qF "set number" /etc/xdg/nvim/sysinit.vim || echo "set number" | sudo tee -a /etc/xdg/nvim/sysinit.vim > /dev/null
grep -qF "set wrap!" /etc/xdg/nvim/sysinit.vim || echo "set wrap!" | sudo tee -a /etc/xdg/nvim/sysinit.vim > /dev/null

echo ""
echo "Installing XFCE..."
echo ""
sudo pacman -S --needed --noconfirm - <xfce
xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "|HMC"
xfconf-query -c xfwm4 -p /general/raise_with_any_button -n -t bool -s false
xfconf-query -c xfwm4 -p /general/mousewheel_rollup -n -t bool -s false
xfconf-query -c xfwm4 -p /general/scroll_workspaces -n -t bool -s false
xfconf-query -c xfwm4 -p /general/placement_ratio -n -t int -s 100
xfconf-query -c xfwm4 -p /general/show_popup_shadow -n -t bool -s true
xfconf-query -c xfwm4 -p /general/wrap_windows -n -t bool -s false
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 32
xfconf-query -c xfce4-panel -p /panels/panel-1/icon-size -n -t int -s 0
xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -n -t bool -s false
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -n -t string -s "desktop-environment-xfce"
#xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 -a
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -n -t bool -s false
xfconf-query -c xfce4-notifyd -p /do-slideout -n -t bool -s true
xfconf-query -c xfce4-notifyd -p /notify-location -n -t int -s 3
xfconf-query -c xfce4-notifyd -p /expire-timeout -n -t int -s 5
xfconf-query -c xfce4-notifyd -p /initial-opacity -n -t double -s 1
xfconf-query -c xfce4-notifyd -p /notification-log -n -t bool -s true
xfconf-query -c xfce4-notifyd -p /log-level -n -t int -s 1
xfconf-query -c xfce4-notifyd -p /log-max-size -n -t int -s 0
xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 100
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "Papirus-Dark"
sudo sed -i 's/^#greeter-setup-script=.*/greeter-setup-script=\/usr\/bin\/numlockx on/' /etc/lightdm/lightdm.conf
sudo cp lightdm-gtk-greeter.conf /etc/lightdm/
sudo systemctl enable lightdm

echo ""
read -r -p "Do you want to install Colloid GTK Theme? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    git clone https://github.com/vinceliuice/Colloid-gtk-theme.git --depth=1
    cd Colloid-gtk-theme/
    sudo ./install.sh
    cd ..
    rm -rf Colloid-gtk-theme/

    xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Colloid-Dark"
    xfconf-query -c xfwm4 -p /general/theme -n -t string -s "Colloid-Dark"
fi

echo ""
read -r -p "Do you want to configure git? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    ssh-keygen -C "$git_email"
    git config --global gpg.format ssh
    git config --global user.signingkey /home/$(whoami)/.ssh/id_ed25519.pub
    git config --global commit.gpgsign true
fi

echo ""
if [ "$(pactree -r chaotic-keyring && pactree -r chaotic-mirrorlist)" ]; then
    echo -e "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.d/custom > /dev/null
else
    echo ""
    read -r -p "Do you want Chaotic-AUR? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --needed --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.d/custom > /dev/null
        sudo pacman -Syu

        if [ "$(pactree -r yay || pactree -r yay-bin)" ]; then
            true
        else
            sudo pacman -S --needed --noconfirm yay
        fi
    fi
fi

if [ "$(pactree -r yay || pactree -r yay-bin)" ]; then
    true
else
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git --depth=1
    cd yay-bin
    yes | makepkg -si
    cd ..
    rm -rf yay-bin
fi

yay -S --answerclean A --answerdiff N --removemake --cleanafter --save

echo ""
read -r -p "Do you want to install Firefox? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm firefox firefox-ublock-origin
fi

echo ""
read -r -p "Do you want to install Google Chrome? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    yay -S --needed --noconfirm google-chrome
fi

echo ""
read -r -p "Do you want Bluetooth Service? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm bluez bluez-utils
    sudo systemctl enable bluetooth
fi

echo ""
read -r -p "Do you want to install HPLIP (Driver for HP printers)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm hplip python-pyqt5 sane
    hp-plugin -i
fi

echo ""
read -r -p "Do you want to install Code-OSS? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm code
    echo ""
    read -r -p "Do you want to install proprietary VSCode marketplace? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        yay -S --needed --noconfirm code-marketplace
    fi
fi

echo ""
read -r -p "Do you want to install Telegram? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -S --needed --noconfirm telegram-desktop
fi

echo ""
read -r -p "Do you want to install Cloudflare Warp? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    bash -c "$(curl -Ss https://gist.githubusercontent.com/ayu2805/7ad8100b15699605fbf50291af8df16c/raw/warp-update)"
    warp-cli generate-completions fish | sudo tee /etc/fish/completions/warp-cli.fish > /dev/null
fi

echo ""
read -r -p "Do you want Gaming Stuff? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    bash -c "$(curl -sS https://gist.githubusercontent.com/ayu2805/37d0d1740cd7cc8e1a37b2a1c2ecf7a6/raw/archlinux-gaming-setup)"
fi

cp QtProject.conf ~/.config/

echo ""
echo "You can now reboot your system"
