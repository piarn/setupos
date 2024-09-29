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

# Check for if snap is installed
if command -v snap &> /dev/null; then
    echo "Snap is installed."
    # Stop the Snap service
    systemctl stop snapd.service > /dev/null 2>&1
    systemctl stop snapd.socket > /dev/null 2>&1

    # Disable the Snap service
    systemctl disable snapd.service > /dev/null 2>&1
    systemctl disable snapd.socket > /dev/null 2>&1
    # Remove Snap and its associated packages
    apt purge snapd -y > /dev/null 2>&1
    
    # Remove Snap cache and configuration
    rm -rf /var/cache/snapd > /dev/null 2>&1
    rm -rf /var/snap > /dev/null 2>&1
    rm -rf /snap > /dev/null 2>&1
    rm -rf ~/snap > /dev/null 2>&1
    
    # Optionally remove related packages (e.g., core, gnome-software-plugin-snap)
    apt purge gnome-software-plugin-snap -y > /dev/null 2>&1
    
    # Autoremove to clean up unnecessary dependencies
    apt autoremove -y > /dev/null 2>&1
    
    # Prevent Snap from being reinstalled by marking it as held
    echo "snapd hold" | dpkg --set-selections > /dev/null 2>&1
    
    # Optionally remove the snapd repository (for Ubuntu)
    if [ -f /etc/apt/sources.list.d/snapd.list ]; then
        rm /etc/apt/sources.list.d/snapd.list > /dev/null 2>&1
    fi
    
    # Notify the user without output
else
    echo "Snap is not installed."
fi

# Confirm script is finished
echo "The setup has finished..."
echo "Exiting..."
exit 0
