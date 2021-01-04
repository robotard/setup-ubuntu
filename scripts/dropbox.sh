
#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

#Add source
echo 'deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main' | sudo tee -a /etc/apt/sources.list.d/dropbox.list
#Add key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E

#Update and Install Dropbox
sudo apt update -y && sudo apt install python3-gpg dropbox -y

#Start dropbox and follow instructions (then ctrl - c after )
dropbox start -i

	
cd $currentDirectory
cd ..