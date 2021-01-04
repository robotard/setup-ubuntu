#!/bin/bash

home_folder="/home/$(logname)"
currentDirectory="$(pwd)"
echo $currentDirectory

pre_5_9_version="displaylink-driver-5.3.1.34.run"
latestversion=true
patch=true

echo -e "\n##### Installing - DisplayLink ###"

apt install wget libdrm-dev libelf-dev

version=`wget -q -O - https://www.displaylink.com/downloads/ubuntu | grep "download-version" | head -n 1 | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/'`

echo -e "\n##### Current version from DisplayLink Website = $version"
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

				echo -e "\n$driver_dir"
if [ -d "$driver_dir" ]
then
	echo -e "\nRemoving prior: \"$driver_dir\" directory"
	rm -rf "$driver_dir"
fi
mkdir "$driver_dir"
echo -e "\n#########################################"

echo -e "\n##### Working directory - $(pwd)"
echo -e "\n##### - DRIVER DIR - $driver_dir"

unzip "$dlFile" -d "$driver_dir" 

cd $driver_dir
ls

#### Checking if we need to patch... 
if [ ! -f "$pre_5_9_version" ]; then
	echo -e "\n##### Newer Version Found"
    latestversion=false
else
	echo -e "\n##### Current version - Needs EVDI patch"
fi

echo -e "\n##### Adding Correct Permissions - chmod +x displaylink-driver-${version}.[0-9]*.run"
chmod +x displaylink-driver-${version}.[0-9]*.run

echo -e "\n##### Extracting current driver files - $driver_dir/displaylink-driver-${version}*.run --keep --noexec"
./displaylink-driver-${version}.[0-9]*.run --keep --noexec

#updated for Kernel 5.9 and 5-10

if [ $latestversion != true ]; then
	echo -e "\nDOWNLOADED DisplyLink VERSION NEWER THAN THE PATCH"
	echo -e "\n-------------------------------------------------------------"
	echo
	read -p "DO YOU STILL WANT TO APPLY THE PATCH ? Y/N ?" -n 1 -r
	echo

	if [[ $REPLY =~ ^[Yy]$ ]] ; then
		echo -e "\n##### PATCH **WILL BE** APPLIED"
	    patch=true
	else
		echo -e "\n##### PATCH WILL **NOT** APPLIED"
		patch=false

	fi
fi

	echo -e "\n##### PATCH STATUS = $patch"

if [ $patch = true ] ; then

	echo -e "\n##### PATCHING"
	sudo git clone https://github.com/DisplayLink/evdi.git
	cd evdi
	sudo git checkout v1.7.x
	tar cf evdi.tar.gz *
	echo -e "\n##### - Copying from $(pwd) to $driver_dir"
	sudo cp evdi.tar.gz $driver_dir

	cd ../displaylink-driver-5.3.1.34

fi
echo -e "\n##### - Installing from $(pwd)"
#sudo ./displaylink-installer.sh install
	
echo -e "\n### Finishing - dISPLAYlINK ###"

cd $currentDirectory
cd ..