#!/bin/bash

clear;

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
else
    echo "root..."
fi

# Check if the current shell is bash
if [ -n "$BASH_VERSION" ]; then
    echo "bash..."
else
    echo "This script is not running in Bash."
    exit 1
fi

# Check for Ubuntu by reading /etc/os-release
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        echo "ubuntu..."
    else
        echo "This script is not running on Ubuntu."
        exit 1
    fi
else
    echo "Unable to determine the OS."
    exit 1
fi

# Check if the package manager is apt
if command -v apt > /dev/null; then
    echo "apt..."
    # Place your commands that require apt here
else
    echo "This system does not use APT as the package manager. Exiting."
    exit 1
fi

# Checks passed
echo "All checks have passed, proceeding..."

echo "Updating the package list..."
sudo apt update &>/dev/null
echo "Upgrading the installed packages..."
sudo apt upgrade -y &>/dev/null
echo "Removing unused packages..."
sudo apt autoremove -y &>/dev/null

echo "Update and upgrade process was completed..."

# Confirm script is finished
echo "The setup has finished..."
echo "Exiting..."
exit 0
