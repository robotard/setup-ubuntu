#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

echo "### Installing - Unified Remote ###"
#Download Unified Remote
cd $home_folder/Downloads/
wget -O urserver.deb http://www.unifiedremote.com/d/linux-x64-deb

#Install it....
sudo dpkg -i urserver.deb

#Clear up...  ---Do your own garbage....
#sudo mr -rf urserver.deb

#Start Server...
sudo ./opt/urserver/urserver-start

#Open in browser - don't sudo here... browser should be your use else it spazzes

echo "Opening Unified Remote in browser as $(logname) cos can't sudo it... "
sudo -u $(logname) xdg-open 'http://localhost:9510/web/'
echo "Thanks for remembering..."


echo "### Finishing - Unified Remote ###"

cd $currentDirectory
cd ..