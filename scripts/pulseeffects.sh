echo "Installing Pulse Effects (and prereqs)"
sudo apt install pulseeffects pulseaudio --install-recommends -y

echo "Installing plugins"
sudo apt install gstreamer1.0-plugins-base \
	gstreamer1.0-plugins-good \
	gstreamer1.0-plugins-bad \
	gstreamer1.0-convolver-pulseeffects \
	gstreamer1.0-crystalizer-pulseeffects \
	gstreamer1.0-autogain-pulseeffects \
	lsp-plugins \
	calf-plugins \
	zam-plugins \
	rubberband-ladspa \
	liblilv-0-0 \
	mda-lv2 \
	libsndfile1 \
	libsamplerate0 \
	libebur128-1 -y
	
echo "Copying presets"
sudo rsync -auv "$(pwd)/scripts/PulseEffects/" "/home/$(logname)/.config/"
sudo chown -R "$(logname):"$(logname) "/home/$(logname)/.config/PulseEffects/"

#DO THIS WITH PULSE EFFECTS AND DROPBOX:
# #Make Dropbox Symlink - LIKE A BOSS
# sudo mkdir $home_folder/Dropbox/Dev $home_folder/Documents/Dev
# sudo ln -s $home_folder/Dropbox/Dev $home_folder/Documents/Dev

cd ..
echo "$(pwd)"
pulseaudio -k

