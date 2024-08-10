MAC_ADDRESS=$(cat /sys/class/net/wlan0/address | sed 's/://g')
SSID="SHARI_${MAC_ADDRESS}"

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

INTERFACE="wlan0"

CONNECTED=$(iw dev ${INTERFACE} link | grep "Connected")

if [ -z "${CONNECTED}" ]; then
    systemctl start hostapd
fi
