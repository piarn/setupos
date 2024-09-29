#!/bin/bash
clear
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Check if the shell is Bash
if [[ "$BASH" == "" ]]; then
    echo "Error: This script must be run in the Bash shell."
    exit 1
fi

# Detect the Operating System
OS_NAME=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')

# Check if the OS is Ubuntu
if [[ "$OS_NAME" != "Ubuntu" ]]; then
    echo "Error: This script is intended to run on Ubuntu."
    exit 1
fi

# Update and Upgrade the System
echo "Updating the package list..."
apt update > /dev/null 2>&1

echo "Upgrading the installed packages..."
apt upgrade -y > /dev/null 2>&1

# Confirm changes
echo "Configuration completed."

# Exit
exit 0
