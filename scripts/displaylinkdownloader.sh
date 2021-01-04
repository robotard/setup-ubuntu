#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

echo "### Installing - DisplayLink ###"

apt install wget libdrm-dev libelf-dev

version=`wget -q -O - https://www.displaylink.com/downloads/ubuntu | grep "download-version" | head -n 1 | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/'`
# define download url to be the correct version
dlurl="https://www.displaylink.com/"`wget -q -O - https://www.displaylink.com/downloads/ubuntu | grep 'class="download-link"' | head -n 1 | perl -pe '($_)=/<a href="\/([^"]+)"[^>]+class="download-link"/'`
driver_dir="$(pwd)/displaylink-driver-$version"
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"

dlFile="DisplayLink_Ubuntu_${version}.zip"

dlfileid=$(echo $dlurl | perl -pe '($_)=/.+\?id=(\d+)/')
				echo -e "\nDownloading DisplayLink Ubuntu driver:\n"
				#read "poopey"
				wget -O DisplayLink_Ubuntu_${version}.zip "--post-data=fileId=$dlfileid&accept_submit=Accept" $dlurl
				# make sure file is downloaded before continuing
				if [ $? -ne 0 ]
				then
					echo -e "\nUnable to download Displaylink driver\n"
					exit
				fi

				echo "$driver_dir"
if [ -d "$driver_dir" ]
then
	echo "Removing prior: \"$driver_dir\" directory"
	rm -rf "$driver_dir"
fi
mkdir "$driver_dir"
echo "#########################################"

pwd
echo "##### - DRIVER DIR - $driver_dir"

unzip "$dlFile" -d "$driver_dir" 

cd $driver_dir
ls
echo "##### - chmod +x displaylink-driver-${version}.[0-9]*.run"
chmod +x displaylink-driver-${version}.[0-9]*.run

echo ".$driver_dir/displaylink-driver-${version}*.run --keep --noexec"
./displaylink-driver-${version}.[0-9]*.run --keep --noexec

#updated for Kernel 5.9 and 5-10

sudo git clone https://github.com/DisplayLink/evdi.git
cd evdi
sudo git checkout v1.7.x
tar cf evdi.tar.gz *
echo "##### - Copying from $(pwd) to $driver_dir"
sudo cp evdi.tar.gz $driver_dir

cd ../displaylink-driver-5.3.1.34

echo "##### - Installing from $(pwd)"
sudo ./displaylink-installer.sh install
	
echo "### Finishing - dISPLAYlINK ###"

cd $currentDirectory
cd ..