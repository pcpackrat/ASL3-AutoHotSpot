# Start with asl3 pi image
# Setup node per ASL instructions.
# Logon to shell and switch to root
sudo su -

# run raspi-config and set the wifi region to US

# For autohotspot, install some things:
sudo apt-get install hostapd dnsmasq telnet traceroute git php libapache2-mod-php 

# Copy executables from git respository
cp ASL3-AutoHotSpot/usr/local/sbin/start_hostapd.sh /usr/local/sbin
chmod +x /usr/local/sbin/start_hostapd.sh

cp ASL3-AutoHotSpot/etc/init.d/autohostspot /etc/init.d
chmod +x /etc/init.d/autohotspot

# Copy web files from git:
cp ASL3-AutoHotSpot/var/www/html/* /var/www/html

/var/www/html/upload.php
/var/www/html/create_config.php
/var/www/html/scan_wifi.py
/var/www/html/logon.php

# Allow www-data to access network devices:
usermod -aG netdev www-data

# add to sudo using visudo:
www-data ALL=(ALL) NOPASSWD: /sbin/iwlist
www-data ALL=(ALL) NOPASSWD: /usr/bin/nmcli
www-data ALL=(ALL) NOPASSWD: /usr/sbin/reboot

# Copy and make executable AutoAP components from git:
cp ASL3-Mods/etc/init.d/autohotspot /etc/init.d/
chmod +x /etc/init.d/autohotspot


Copy hostapd.service from git:
/usr/lib/systemd/system/hostapd.service

# unmask and disable hostapd.service
systemctl unmask hostapd.service
systemctl disable hostapd.service

# copy dnsmasq.conf from git
cp ASL3-Mods/etc/dnsmasq.conf /etc

# Open firewall ports for dhcp and DNS in the web admin
edit /etc/firewalld/zones/allstarlink.xml and add the following services:
 <service name="dns"/>
 <service name="dhcp"/>

# modify apache to load the logon.php for android and apple online checks:
# Edit /etc/apache2/sites-available/000-default.conf
Add to <VirtualHost *:80> section
-----------------------------------
RewriteEngine On

# Redirect Apple devices for captive portal detection
RewriteRule ^/hotspot-detect.html$ /logon.php [L,R=302]

# Redirect Android devices for captive portal detection
RewriteRule ^/generate_204$ /logon.php [L,R=302]

# Redirect Windows devices for captive portal detection
RewriteRule ^/ncsi.txt$ /logon.php [L,R=302]
-----------------------------------

# modify AllowOveride to All in /etc/apache2/apache2.conf:
---------------------------------------------------------
<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
---------------------------------------------------------

# add the following to rc.local:

/usr/local/bin/start_hostapd.sh
