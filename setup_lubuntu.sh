#!/bin/bash

sudo apt update && sudo apt upgrade
sudo apt install openssh-server -y
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
sudo systemctl stop lightdm
sudo systemctl disable lightdm
reboot

https://cdimage.ubuntu.com/lubuntu/releases/18.04/release/
