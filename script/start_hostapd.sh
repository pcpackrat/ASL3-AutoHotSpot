#!/bin/bash

# Generate the SSID based on the MAC address of wlan0
MAC_ADDRESS=$(cat /sys/class/net/wlan0/address | sed 's/://g')
SSID="ASL3_${MAC_ADDRESS}"

# Ethernet and Wi-Fi interfaces to check
ETH_INTERFACE="eth0"
WIFI_INTERFACE="wlan0"

# Write configuration to hostapd.conf
echo "interface=wlan0
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=YourPassword
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf

# Check if Ethernet is connected
ETH_CONNECTED=$(cat /sys/class/net/$ETH_INTERFACE/carrier 2>/dev/null)

# Check if wlan0 is connected to a network
WIFI_CONNECTED=$(iw dev $WIFI_INTERFACE link | grep "Connected")

# Start hostapd if either Ethernet or Wi-Fi is connected
if [[ "$ETH_CONNECTED" -eq 0 ]] && [[ -z "$WIFI_CONNECTED" ]]; then
    systemctl start hostapd
else
    systemctl stop dnsmasq
fi
