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
The default wifi password is YourPassword and can be changed in the start_hostapd.sh file.
