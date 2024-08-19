#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" >&2
   exit 1
fi

apt -y install hostapd dnsmasq

cp start_hostapd.sh /usr/local/sbin
chmod +x /usr/local/sbin/start_hostapd.sh

cp autohotspot.service /etc/systemd/system
systemctl enable autohotspot.service

cp 99-killhostapd-eth_up /etc/NetworkManager/dispatcher.d
chmod +x /etc/NetworkManager/dispatcher.d/99-killhostapd-eth_up

# Copy web files from git:
cp wifisetup.py /var/www/cgi-bin

# Allow www-data to access network devices:
usermod -aG netdev www-data

# setup sudoers
NEW_SUDO_ENTRIES=$(cat <<EOF
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

# Copy service files
cp hostapd.service /usr/lib/systemd/system/hostapd.service
cp autohotspot.service /etc/systemd/system/autohotspot.service
systemctl enable autohotspot.service

# unmask and disable hostapd.service
systemctl unmask hostapd.service
systemctl disable hostapd.service

# copy dnsmasq.conf from git
cp dnsmasq.conf /etc

# Open Firewall for DHCP and DNS
/usr/bin/firewall-cmd --zone=allstarlink --add-service=dns --permanent
/usr/bin/firewall-cmd --zone=allstarlink --add-service=dhcp --permanent

# Modify 000-Default.conf
MARKERWS="</VirtualHost>"

NEW_APACHE_ENTRIES=$(cat <<EOF

<VirtualHost 10.5.5.5:80>
        ServerAdmin webmaster@localhost
        DocumentRoot/var/www/html
        ErrorLog ${APACHE_LOG_DIR}/cgi_error.log
        CustomLog ${APACHE_LOG_DIR}/cgi_access.log combined
        RewriteEngine On

        # Redirect Apple devices for captive portal detection
        RewriteRule ^/hotspot-detect.html$ /wifisetup.py [L,R=302]

        # Redirect Android devices for captive portal detection
        RewriteRule ^/generate_204$ /wifisetup.py [L,R=302]

        # Redirect Windows devices for captive portal detection
        RewriteRule ^/ncsi.txt$ /wifisetup.py [L,R=302]

        # Redirect Windows devices for captive portal detection
        RewriteRule ^/connectiontest.txt$ /wifisetup.py [L,R=302]

        ScriptAlias /cgi-bin/ /var/www/autohotspot/
        <Directory "/var/www/autohotspot/">
            AllowOverride None
            Options +ExecCGI
            AddHandler cgi-script .py
            Require all granted
        </Directory>

</VirtualHost>
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
