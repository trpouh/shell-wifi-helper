#!/bin/bash

# Internal ID used for the AccessPoint connection
HOTSPOT_ID=Hotspot

# Check installation before every operation
IS_INSTALLED=$(dpkg -s network-manager | grep Status: | grep ok)

if [ -z "IS_INSTALLED" ]; then
    echo "Network-manager not installed. Install via: apt-get install network-manager"
    exit 1
fi

# usage: disconnect
disconnect()
{
    CONNECTION=$(nmcli dev status | awk '{if($2=="wifi")print$4}')
    echo "Disconnecting from Wifi: $CONNECTION";
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
}

# usage: connect <ssid> [password]
connect()
{
    SSID=$1

    echo "Connecting to Wifi: $SSID";

    PASSWD=$([ -z "$2" ] && echo "" || echo "password $2")

    nmcli dev wifi connect $SSID $PASSWD
}

# usage: get_ssids
get_ssids()
{
    SSIDS=$(sudo iw wlan0 scan | awk -f "scan.awk")
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
    nmcli con modify $HOTSPOT_ID 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
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
