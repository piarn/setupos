#!/bin/bash
clear

# Log file
LOG_FILE="/var/log/setupos.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print messages
log_message() {
    echo -e "\n=== $1 ==="
}

# Function to check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root."
        exit 1
    fi
}

# Function to check if the shell is Bash
check_bash() {
    if [[ -z "$BASH_VERSION" ]]; then
        echo "Error: This script must be run in the Bash shell."
        exit 1
    fi
}

# Function to check if the OS is Ubuntu
check_os() {
    OS_NAME=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
    if [[ "$OS_NAME" != "Ubuntu" ]]; then
        echo "Error: This script is intended to run on Ubuntu. Detected: $OS_NAME."
        exit 1
    fi
}

# Function to show current system info
show_system_info() {
    log_message "Current System Information"
    echo "Hostname: $(hostname)"
    echo "OS: $OS_NAME"
}

# Function to confirm user input
confirm_action() {
    read -p "$1 (y/n): " -n 1 -r
    echo  # Move to the next line after the prompt
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
}

# Function to perform package management
update_system() {
    echo "Updating the package list..."
    if ! apt update; then
        echo "Error: Failed to update package list."
        exit 1
    fi

    echo "Upgrading the installed packages..."
    if ! apt upgrade -y; then
        echo "Error: Failed to upgrade packages."
        exit 1
    fi

    echo "Removing unused packages..."
    if ! apt autoremove -y; then
        echo "Error: Failed to remove unused packages."
        exit 1
    fi
}

# Function to set the timezone
set_timezone() {
    local timezone=$1
    echo "Setting the timezone to '$timezone'..."
    if timedatectl set-timezone "$timezone"; then
        echo "Timezone successfully set."
    else
        echo "Error: Failed to set timezone."
    fi
}

# Main script execution
check_root
check_bash
check_os
show_system_info

confirm_action "Do you want to proceed with system updates and upgrades?"

update_system

confirm_action "Do you want to set the timezone to 'Europe/Vilnius'?"
set_timezone "Europe/Vilnius"

# Confirm changes
log_message "Configuration Completed"
echo "Log of actions can be found in $LOG_FILE."

# Exit
exit 0
