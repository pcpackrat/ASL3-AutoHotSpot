#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" >&2
   exit 1
fi

apt -y isntall hostapd dnsmasq php libapache2-mod-php

cp start_hostapd.sh /usr/local/sbin
chmod +x /usr/local/sbin/start_hostapd.sh

cp autohotspot /etc/init.d
chmod +x /etc/init.d/autohotspot

# Copy web files from git:
cp *.php /var/www/html
cp scan_wifi.py /var/www/html

# Allow www-data to access network devices:
usermod -aG netdev www-data

# setup sudoers
NEW_SUDO_ENTRIES=$(cat <<EOF
www-data ALL=(ALL) NOPASSWD: /sbin/iwlist
www-data ALL=(ALL) NOPASSWD: /usr/bin/nmcli
www-data ALL=(ALL) NOPASSWD: /usr/sbin/reboot
EOF
)

MARKER="# User privilege specification"

# Create a temporary file to hold the modified sudoers configuration
TEMPFILE=$(mktemp)

# Read the sudoers file and insert the new entries under the marker
awk -v marker="$MARKER" -v entries="$NEW_SUDO_ENTRIES" '
    $0 ~ marker {print; print entries; next} 1' /etc/sudoers > "$TEMPFILE"

# write out to /etc/sudoers file
cp "$TEMPFILE" /etc/sudoers
rm "$TEMPFILE"
# Copy hostapd.service from git:
cp hostapd.service /usr/lib/systemd/system/hostapd.service

# unmask and disable hostapd.service
systemctl unmask hostapd.service
systemctl disable hostapd.service

# copy dnsmasq.conf from git
cp dnsmasq.conf /etc

# Open firewall ports for dhcp and DNS in the web admin
MARKERFW='<service name="http"/>'

NEW_FIREWALL_ENTRIES=$(cat <<EOF
  <service name="dns"/>
  <service name="dhcp"/>
EOF
)

TEMPFILE=$(mktemp)

awk -v marker="$MARKERFW" -v entries="$NEW_FIREWALL_ENTRIES" '
    $0 ~ marker {print; print entries; next} 1' /etc/firewalld/zones/allstarlink.xml > "$TEMPFILE"

mv "$TEMPFILE" /etc/firewalld/zones/allstarlink.xml

# Modify 000-Default.conf
MARKERWS="Include conf-available/serve-cgi-bin.conf"

NEW_APACHE_ENTRIES=$(cat <<EOF
RewriteEngine On

# Redirect Apple devices for captive portal detection
RewriteRule ^/hotspot-detect.html$ /logon.php [L,R=302]

# Redirect Android devices for captive portal detection
RewriteRule ^/generate_204$ /logon.php [L,R=302]

# Redirect Windows devices for captive portal detection
RewriteRule ^/ncsi.txt$ /logon.php [L,R=302]
EOF
)

TEMPFILE=$(mktemp)

awk -v marker="$MARKERWS" -v entries="$NEW_APACHE_ENTRIES" '
    $0 ~ marker {print; print entries; next} 1' /etc/apache2/sites-available/000-default.conf > "$TEMPFILE"

mv "$TEMPFILE" /etc/apache2/sites-available/000-default.conf

# Modify apache2.conf
# Define the file to be modified
CONFIG_FILE="/etc/apache2/apache2.conf"

# Define the directory block to target
DIRECTORY_BLOCK="<Directory /var/www/>"

# Create a temporary file to hold the modified configuration
TEMPFILE=$(mktemp)

# Use awk to find the correct <Directory> block and change AllowOverride None to All
awk -v block="$DIRECTORY_BLOCK" '
    $0 ~ block, $0 ~ /<\/Directory>/ {
        if ($0 ~ /AllowOverride None/) {
            sub(/AllowOverride None/, "AllowOverride All")
        }
    }
    {print}
' "$CONFIG_FILE" > "$TEMPFILE"

# Replace the original file with the modified file
mv "$TEMPFILE" "$CONFIG_FILE"

# add start_hostapd.sh to rc.local
MARKERRC="By default this script does nothing."

# Define the sudoers entry you want to add
NEW_RCLOCAL_ENTRY="/usr/local/sbin/start_hostapd.sh"

# Create a temporary file to hold the new sudoers configuration
TEMPFILE=$(mktemp)

# Read the sudoers file and insert the new entries under the marker
awk -v marker="$MARKERRC" -v entries="$NEW_RCLOCAL_ENTRIES" '
    $0 ~ marker {print; print entries; next} 1' /etc/rc.local > "$TEMPFILE"

# write out to /etc/sudoers file
cp "$TEMPFILE" /etc/rc.local
