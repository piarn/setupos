#!/bin/bash

clear

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
else
    echo "Running as root..."
fi

# Check if the current shell is bash
if [ -n "$BASH_VERSION" ]; then
    echo "Running in Bash..."
else
    echo "This script is not running in Bash."
    exit 1
fi

# Check for Ubuntu by reading /etc/os-release
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        echo "Ubuntu detected..."
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
    echo "APT package manager found..."
else
    echo "This system does not use APT as the package manager. Exiting."
    exit 1
fi

# Checks passed
echo "All checks have passed, proceeding..."

# Redirecting output to /dev/null while maintaining echo statements
{
    echo "Updating the system package list..."
    sudo apt update &>/dev/null
    echo "Upgrading the installed system packages..."
    sudo apt upgrade -y &>/dev/null
    echo "Removing unused system packages..."
    sudo apt autoremove -y &>/dev/null
} &>/dev/null

echo "Update and upgrade process was completed."

# Confirm script is finished
echo "The setup has finished..."
echo "Exiting..."
exit 0
