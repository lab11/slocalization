#!/bin/bash

IP_ADDRESS=$1

#First see if there's a route to the radio
PING_RET=$(ping -w 1 -c 1 $IP_ADDRESS)
if [ $? -ne 0 ]
then
    echo -e "\033[0;31mERROR\033[0m: No USRP at address $IP_ADDRESS"
    exit
fi

#Increase size of UDP buffers
sudo sysctl -w net.core.rmem_max=50000000
sudo sysctl -w net.core.wmem_max=50000000

#Maximize the number of descriptors for the NIC
INTERFACE_NAME=`ip -o route get $IP_ADDRESS | awk '{ print $3 }'`
MAX_DESCRIPTORS=`ethtool -g $INTERFACE_NAME | awk 'NR==3,NR==3 { print $2 }'`
echo -n "Configuring NIC to maximum number of descriptors: "
echo -n $MAX_DESCRIPTORS
echo ""
sudo ethtool -G $INTERFACE_NAME tx $MAX_DESCRIPTORS rx $MAX_DESCRIPTORS

#NIC takes a while to accept the new parameters...
echo "Waiting a second for NIC to accept new settings..."
sleep 5
