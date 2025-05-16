#!/bin/bash

VNC_PASS="pas123"
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

sudo apt install -y vlc onboard gparted snapd zsh telegram-desktop
sudo snap install snap-store
sudo snap install notepad-plus-plus
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/x-matroska


sudo pkill firefox || true
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install firefox -y

sudo apt install lightdm -y
sudo dpkg-reconfigure lightdm
cat /etc/X11/default-display-manager
sudo apt remove gdm3 -y
sudo apt install x11vnc net-tools -y
x11vnc -storepasswd <<EOF
$VNC_PASS
$VNC_PASS
y
EOF
sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=VNC Server for X11
Requires=display-manager.service

[Service]
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth $HOME_DIR/.vnc/passwd -rfbport 5900 -shared
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable x11vnc
sudo systemctl start x11vnc
sudo systemctl status x11vnc
sudo apt remove --purge -y matchbox-keyboard

sudo apt remove --purge -y audacious gnome-mpv gnome-mines gnome-sudoku xpad simple-scan guvcview lxmusic sylpheed pidgin transmission-gtk xfburn
sudo apt autoremove -y
sudo apt clean

sudo systemctl stop cups
sudo systemctl disable cups

#sudo systemctl stop lightdm
#sudo systemctl disable lightdm
#reboot
