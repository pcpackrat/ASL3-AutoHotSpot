# Apple Users !!!  This is not handling apostrophes in the SSID. You will need to rename your device 

Open Settings -> Tap General -> Scroll down and tap About -> Tap your device name -> Enter new name without special chars

# sudo into a root shell
sudo su
# install git
apt install git
# clone repository
git clone https://github.com/pcpackrat/ASL3-AutoHotSpot.git
# Change into the ASL3-AutoHotSpot/script directory
cd ASL3-AutoHotSpot/script
# make the script executable
chmod +x install_autohotspot
# run the script:
./install_autohotspot.sh
# Notes
The SSID will be ASL3_{MAC_ADDRESS}

The default wifi password is YourPassword and can be changed in the start_hostapd.sh file.

If no access points show up, try power cycling the pi
