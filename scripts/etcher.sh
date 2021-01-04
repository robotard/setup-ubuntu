
#!/bin/bash

#Install Etcher...
home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 379CE192D401AB61
sudo apt update -y && sudo apt install balena-etcher-electron -y

cd $currentDirectory
cd ..