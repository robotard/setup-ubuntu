
#!/bin/bash

#Install Nemo...
home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory


echo "++ INSTALLING Nemo Filemanager"
sudo apt install nemo -y
echo "++ Configuring as default filemanager, and setting autostart"
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
#Add Nemo Autostart Entry
[ ! -d "$home_folder/.config/autostart" ] && mkdir -p "$home_folder/.config/autostart"
echo -e "[Desktop Entry]\nType=Application\nExec=nemo-desktop\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_GB]=Nemo Desktop\nName=Nemo Desktop\nComment[en_GB]=Nemo File Manager AutoStart\nComment=Nemo File Manager AutoStart" > $home_folder/.config/autostart/nemo-desktop.desktop

cd $currentDirectory
cd ..