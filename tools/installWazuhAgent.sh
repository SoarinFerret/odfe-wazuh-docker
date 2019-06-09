#!/bin/bash

agentVersion="3.9.0-1"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# check for necessary packages
echo "Installing dependencies: curl apt-transport-https lsb-release"
apt update && apt-get install curl apt-transport-https lsb-release -y > /dev/null 2>&1

# add wazuh gpg key
echo "Adding GPG for wazuh repository"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - 

# add the repo
echo "Adding repo to apt sources"
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Install agent and hold so it doesn't update
apt-get update && apt install wazuh-agent=$agentVersion -y > /dev/null 2>&1
apt-mark hold wazuh-agent

echo "Run '/var/ossec/bin/manage_agents -i XXXXX' with the auth key from the server to finish setup"