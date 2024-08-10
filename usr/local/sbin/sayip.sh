#!/bin/bash

if [ -z "$1" ]
  then
    echo "No node number supplied - sayip.sh <node> "
    exit 1
fi

cat /usr/share/asterisk/sounds/en/letters/i.ulaw /usr/share/asterisk/sounds/en/letters/p.ulaw /usr/share/asterisk/sounds/en/address.ulaw > /tmp/ip.ulaw
asterisk -rx "rpt playback $1 /tmp/ip"

for i in $(ip link show | grep " UP " | grep -v lo | grep -v "link/ether" | awk '{print $2}') ; do

        DEVICE=${i/:/}

        ip=$(ip addr show $DEVICE | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}')

        sleep 3
        /usr/local/sbin/speaktext.sh $ip $1
done

rm /tmp/ip.ulaw
