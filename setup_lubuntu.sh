#!/bin/bash

sudo apt update && sudo apt upgrade
sudo apt install openssh-server -y
sudo apt install -y matchbox-keyboard gparted
sudo apt install snapd zsh -y
sudo snap install snap-store
sudo snap install notepad-plus-plus

sudo pkill firefox || true
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install firefox -y

sudo apt install xrdp -y
echo "startlxde" > ~/.xsession
sudo adduser xrdp ssl-cert

sudo apt autoremove -y




sudo apt-get install lightdm -y
sudo dpkg-reconfigure lightdm
cat /etc/X11/default-display-manager
sudo apt-get remove gdm3 -y
sudo apt-get install x11vnc net-tools
x11vnc -storepasswd
sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=VNC Server for X11
Requires=display-manager.service

[Service]
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/USERNAME/.vnc/passwd -rfbport 5900 -shared
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

sudo systemctl stop lightdm
sudo systemctl disable lightdm
reboot

https://cdimage.ubuntu.com/lubuntu/releases/18.04/release/
