#!/bin/bash

# Check installation before every operation
IS_INSTALLED=$(dpkg -s network-manager | grep Status: | grep ok)
CURRENT_DIR=$(dirname $0)

# This ip will be assigned to the rasp (i.e. the gateway) and the subnet will be used for dhcp ip assignment 
HOTSPOT_SUBNET=10.0.0.1/24

if [ -z "IS_INSTALLED" ]; then
    echo "Network-manager not installed. Install via: apt-get install network-manager"
    exit 1
fi


# Internal ID used for the AccessPoint connection
HOTSPOT_ID=Hotspot

# usage: disconnect
disconnect()
{
    CONNECTION=$(nmcli dev status | awk '{if($2=="wifi")print$4}')
    echo "Disconnecting from Wifi: $CONNECTION"
    nmcli con down id $CONNECTION
}

# usage: is_connected (true, false)
is_connected()
{
    DEV_STATE=$(nmcli dev status | awk '{if($2=="wifi")print $3}')
    WIFI_STATE=$([ "$DEV_STATE" = "connected" ] && echo "true" || echo "false")
    echo "$WIFI_STATE"
}

# usage: get_wifi_ip (ipv4, false)
get_wifi_ip()
{

    IS_CONNECTED=$(is_connected)

    if [ "$IS_CONNECTED" = "false" ]; then
	    echo "false"
	    exit 1
    fi

    WIFI_DEV=$(nmcli dev status | awk '{if($2=="wifi")print $1}')
    IP=$(ip add show $WIFI_DEV | grep "inet " | awk '{print $2}')
    echo "$IP"
    exit 0
}

# https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash
stringContains() { [ -z "$1" ] || { [ -z "${2##*$1*}" ] && [ -n "$2" ];};}

# usage: connect <ssid> [password]
connect()
{
    SSID=$1

    echo "Connecting to Wifi: $SSID;"
    
    PASSWD=$([ -z "$2" ] && echo "" || echo "password $2")

    STATUS=$(nmcli -w 3 dev wifi connect $SSID $PASSWD | grep successful)

    if [ -z "$STATUS" ]; then
        echo "false"
        exit 1
    fi

    echo "true"
    exit 0
}

# usage: get_ssids
get_ssids()
{
    SSIDS=$(sudo iw wlan0 scan | awk -f "$CURRENT_DIR/scan.awk")
    echo "$SSIDS"
}

# usage: start_hotspot <ssid>
start_hotspot()
{
  SSID=$1

  echo "Trying to create Access Point with SSID: $1"

  # get wifi device
  WIFI_DEV=$(nmcli dev status | awk '{if($2=="wifi")print $1}')
  echo "Found Wifi Adapter: $WIFI_DEV"

  # check if device is able to create a hotspot
  CAN_CREATE_HOTSPOT=$(nmcli -f WIFI-PROPERTIES device show $WIFI_DEV | grep ".AP" | awk '{print $2}')

  # create hospot
  if [ "$CAN_CREATE_HOTSPOT" = "yes" ]; then
    echo "Wifi Adapter ($WIFI_DEV) can create Access Point"
    echo "Creating Access Point: $SSID"
    nmcli con add type wifi ifname $WIFI_DEV con-name $HOTSPOT_ID ssid $SSID
    nmcli con modify $HOTSPOT_ID 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared ipv4.addresses $HOTSPOT_SUBNET
    nmcli con up $HOTSPOT_ID

  else
    echo "Error! Access Point cannot be created: Wifi Adapter not able to host AP";
  fi
}

# usage: stop_hotspot
stop_hotspot()
{
    echo "Deleting Access Point ($HOTSPOT_ID)"
    nmcli connection delete id $HOTSPOT_ID
}

"$@"
