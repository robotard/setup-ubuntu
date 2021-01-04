
#!/bin/bash

#Install Nemo...
home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory


echo "++ INSTALLING NVidia"
sudo apt install nvidia-settings -y

cd $currentDirectory
cd ..