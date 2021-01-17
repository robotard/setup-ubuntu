#### INSTALL GNOME EXTENSIONS

#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

sudo apt install gnome-tweaks -y
echo "$(gnome-shell --version)"
sudo apt install gnome-shell-extensions -y
sudo apt install chrome-gnome-shell -y 
