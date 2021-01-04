
#!/bin/bash

kodi_folder="/home/$(logname)/.kodi"
currentDirectory="$(pwd)"
backupfile=""

echo "Installing Kodi"

sudo apt install kodi -y

if [ -d "$currentDirectory/kodi" ] ; then
	cd kodi
	backupfile="$(ls *.zip | head -n 1)"
	echo -e "$(pwd)\n$backupfile"
	if [ -f $backupfile ]; then
		backupfolder="${backupfile%.*}"
		
		#remove any folders
		if [ -d */ ] ; then
			rm -r */
		fi

		#read "trouts" trouts
		echo "Unzipping Kodi backup"
		unzip -q $backupfile
		echo -e "\nBackup Files/Folders:\n$(ls $backupfolder)"
		
		echo -e "\nRestoring Kodi backup"
		sudo rsync -au $backupfolder/* $kodi_folder/
			
		echo -e "\nRestore complete - Clearing up"
		rm -r */
	fi
fi

	
cd $currentDirectory
echo "$(pwd)"
cd ../..
echo "$(pwd)"