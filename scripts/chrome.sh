#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

#Install Chrome Beta
echo "++ INSTALLING Chrome Beta"
sudo apt install gdebi-core
chrome_pkg="google-chrome-beta_current_amd64.deb"
if [ -f "$chrome_pkg" ] ; then
	rm -rf "$chrome_pkg"
fi 
wget https://dl.google.com/linux/direct/$chrome_pkg
sudo gdebi $chrome_pkg --non-interactive
sudo rm -rf google-chrome-beta_current_amd64.deb
	
cd $currentDirectory
cd ..