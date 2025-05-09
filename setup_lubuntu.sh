#!/bin/bash

sudo apt update && sudo apt upgrade
sudo apt install openssh-server -y
sudo apt install cpu-x zsh -y
sudo snap install snap-store
sudo snap install notepad-plus-plus

sudo pkill firefox || true
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo add-apt-repository ppa:lubuntu-desktop/ppa
sudo apt update

sudo apt-get install lubuntu-software-center
sudo apt install firefox -y

sudo apt autoremove -y
sudo systemctl stop lightdm
sudo systemctl disable lightdm
reboot

https://cdimage.ubuntu.com/lubuntu/releases/18.04/release/
