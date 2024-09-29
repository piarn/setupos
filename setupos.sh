#!/bin/bash
clear

# Log file
LOG_FILE="/var/log/setupos.log"
exec > >(tee -a "$LOG_FILE") 2>&1

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

# Show current system info
echo "Current system information:"
echo "Hostname: $(hostname)"
echo "OS: $OS_NAME"

# Prompt for confirmation
read -p "Do you want to proceed with system updates and upgrades? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Update and Upgrade the System
echo "Updating the package list..."
if ! apt update > /dev/null 2>&1; then
    echo "Error: Failed to update package list."
    exit 1
fi

echo "Upgrading the installed packages..."
if ! apt upgrade -y > /dev/null 2>&1; then
    echo "Error: Failed to upgrade packages."
    exit 1
fi

# Clean up unused packages
echo "Removing unused packages..."
if ! apt autoremove -y > /dev/null 2>&1; then
    echo "Error: Failed to remove unused packages."
    exit 1
fi

# Optional timezone configuration
read -p "Do you want to set the timezone to 'Europe/Vilnius'? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting the timezone to 'Europe/Vilnius'..."
    timedatectl set-timezone Europe/Vilnius
fi

# Confirm changes
echo "Configuration completed."
echo "Log of actions can be found in $LOG_FILE."

# Exit
exit 0
