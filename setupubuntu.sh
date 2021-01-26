#!/bin/bash

#Setup folder vars
home_folder="/home/$(logname)"
setup_folder="$(pwd)"
echo "Current user directory - " $home_folder

# TO DO - ADD LOGGINGLog everything
# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3
# exec 1>log.out 2>&1

separator(){
sep="\n-------------------------------------------------------------------\n"
echo -e $sep
}

#update and dist upgrade first
echo "Initial Update & Dist-Upgrade"
sudo apt update -y && sudo apt dist-upgrade -y 

separator	

#Install Essentials
echo "++ INSTALLING essentials"
sudo apt install git wget python build-essential net-tools -y
 
 separator

 #Install Logitech K400+ Wireless KEyboard (Unifying Receiver)
echo "++ INSTALLING Logitech K400+ Keyboard Receiver - Solaar"
sudo apt install solaar-gnome3 -y

separator

#Switch to downloads folder first
cd $home_folder/Downloads
pwd

separator

echo "Moving to setup folder to install from scripts"
cd $setup_folder
echo "$(pwd)"

#Sublime
echo "++ INSTALLING Sublime Text"
./scripts/sublime.sh

separator

#Install Chrome
echo "++ INSTALLING Chrome"
./scripts/chrome.sh

separator
#Install Gnome Tweaks
echo "++ INSTALLING Gnome Tweaks & Extensions"
./scripts/gnome-extensions.sh

#Install DisplayLink
echo "++ INSTALLING DisplayLink"
./scripts/displaylinkdownloader.sh

separator

#Install PulseEffects
echo "++ INSTALLING PulseEffects"
./scripts/pulseeffects.sh

separator

#Install Etcher
echo "++ INSTALLING Etcher"
./scripts/etcher.sh

separator	

#Install Universal Kernel Update Utility 
echo "++ INSTALLING Universal Kernal Update Utility - Add License after"
./scripts/ukuu.sh

separator

#Install Kodi 
echo "++ INSTALLING Kodi"
./scripts/kodi.sh

separator

#Install Nemo
echo "++ INSTALLING Nemo Filemanager"
./scripts/nemo.sh

separator

#Install Gparted
echo "++ INSTALLING GParted"
sudo apt install gparted -y

separator

#Make Dropbox Symlink - LIKE A BOSS
sudo mkdir $home_folder/Dropbox/Dev $home_folder/Documents/Dev
sudo ln -s $home_folder/Dropbox/Dev $home_folder/Documents/Dev

#Install Dropbox
echo "++ INSTALLING Dropbox"
./scripts/dropbox.sh


#Autoremove stuffs
echo "-- AUTOREMOVING autoremovables"
sudo apt autoremove -y

