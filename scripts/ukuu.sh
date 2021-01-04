#!/bin/bash

RESET='\e[0m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'

CHECK_COLOR_SUPPORT() {
	colors=`tput colors`
	if [ $colors -gt 1 ]; then
		COLORS_SUPPORTED=0
	else
		COLORS_SUPPORTED=1
	fi
}

MSG_SUCCESS() {
	add_newline=''
	if [ $COLORS_SUPPORTED -eq 0 ]; then
        printf "${GREEN}> $1 ${RESET}\n"
    else
        printf "> $1\n"
    fi
}

MSG_INFO() {
	add_newline=''
	if [ $COLORS_SUPPORTED -eq 0 ]; then
        printf "${YELLOW}> $1 ${RESET}\n"
    else
        printf "> $1\n"
    fi
}

MSG_ERR() {
	add_newline=''
	if [ $COLORS_SUPPORTED -eq 0 ]; then
        printf "${RED}> E: $1 ${RESET}\n"
    else
        printf "> E: $1\n"
    fi
}

CHECK_COLOR_SUPPORT

if [ "$1" == "no_gui" ]; then
install_gui=0
else
install_gui=1
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

printf "\n"
MSG_INFO "Adding repository..."
echo "deb https://packages.teejeetech.com/ukuu-8ALv9hCkUG stable main" | sudo tee "/etc/apt/sources.list.d/teejeetech-ukuu.list" || exit 1
printf "Created: /etc/apt/sources.list.d/teejeetech-ukuu.list\n\n"

MSG_INFO "Importing public key..."
wget -qO - https://packages.teejeetech.com/archive.key | sudo apt-key add - || exit 1
printf "\n"

dpkg -s apt-transport-https 2>/dev/null | grep Status | grep -q installed
status=$?
if [ $status -ne 0 ]; then
    MSG_INFO "Installing apt-transport-https..."
    sudo apt install -y apt-transport-https
    printf "\n"
fi

MSG_INFO "Refreshing package information..."
sudo apt update
printf "\n"

MSG_INFO "Installing packages..."

if [ ${install_gui} -eq 1 ]; then
sudo apt install -y --install-recommends ukuu ukuu-gtk ukuu-assets
else
sudo apt install -y --install-recommends ukuu
fi

status=$?
printf "\n"

if [ $status -eq 100 ]; then
    MSG_ERR "Another process is using the package manager!"
    MSG_ERR "Close the other process, or retry after sometime"
elif [ $status -eq 0 ]; then
    MSG_SUCCESS "Installed successfully"
    printf "\n"
else
    MSG_ERR "$status"
fi



