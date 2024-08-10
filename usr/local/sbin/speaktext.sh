#!/bin/bash

#
# Script to speak letters and numbers from asterisk sounds
# over a radio node using simpleusb
# by Ramon Gonzalez KP4TR 2014
# modified for ASL 3.0 on Debian 12 by Michael Champion N5ZR 2024

#set -xv

ASTERISKSND=/usr/share/asterisk/sounds/en
LOCALSND=/tmp/randommsg


function speak {
        SPEAKTEXT=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        let SPEAKLEN=$(echo "$SPEAKTEXT" | /usr/bin/wc -m)-1
        COUNTER=0
        rm -f ${LOCALSND}.ulaw
        touch ${LOCALSND}.ulaw
        while [  $COUNTER -lt $SPEAKLEN ]; do
                let COUNTER=COUNTER+1
                CH=$(echo "$SPEAKTEXT"|cut -c${COUNTER})
                if [[ $CH =~ ^[A-Za-z_]+$ ]]; then
                        cat ${ASTERISKSND}/letters/${CH}.ulaw >> ${LOCALSND}.ulaw
                fi
                if [[ ${CH} =~ ^-?[0-9]+$ ]]; then
                        cat /usr/share/asterisk/sounds/en/digits/${CH}.ulaw >> ${LOCALSND}.ulaw
                fi

                case $CH in
                .) cat ${ASTERISKSND}/letters/dot.ulaw >> ${LOCALSND}.ulaw;;
                -) cat ${ASTERISKSND}/letters/dash.ulaw >> ${LOCALSND}.ulaw;;
                =) cat ${ASTERISKSND}/letters/equals.ulaw >> ${LOCALSND}.ulaw;;
                /) cat ${ASTERISKSND}/letters/slash.ulaw >> ${LOCALSND}.ulaw;;
                !) cat ${ASTERISKSND}/letters/exclaimation-point.ulaw >> ${LOCALSND}.ulaw;;
                @) cat ${ASTERISKSND}/letters/at.ulaw >> ${LOCALSND}.ulaw;;
                $) cat ${ASTERISKSND}/letters/dollar.ulaw >> ${LOCALSND}.ulaw;;
                *) ;;
                esac
        done
        if [ $2 == "File" ]
                then
                        exit
                else
                        asterisk -rx "rpt playback $2 ${LOCALSND}"
        fi
}

if [ "$1" == "" -o "$2" == "" ];then
        echo "Usage: speaktext.sh \"abc123\" node#"
        exit
fi

speak "$1" $2
