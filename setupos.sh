#!/bin/bash

clear

LOGFILE="/var/log/script.log"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE"
}

log "Script started."

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root or with sudo."
        exit 1
    else
        echo "Running as root..."
    fi
}

check_bash() {
    if [ -n "$BASH_VERSION" ]; then
        echo "Running in Bash..."
    else
        echo "This script is not running in Bash."
        exit 1
    fi
}

check_ubuntu() {
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
}

check_apt() {
    if command -v apt > /dev/null; then
        echo "APT package manager found..."
    else
        echo "This system does not use APT as the package manager. Exiting."
        exit 1
    fi
}

perform_updates() {
    echo "Updating the system package list..."
    if apt update; then
        log "System package list updated."
    else
        log "Failed to update package list."
        exit 1
    fi

    echo "Upgrading the installed system packages..."
    if apt upgrade -y; then
        log "System packages upgraded."
    else
        log "Failed to upgrade system packages."
        exit 1
    fi

    echo "Removing unused system packages..."
    apt autoremove -y
    log "Unused packages removed."
}

uninstall_snap() {
    if command -v snap &> /dev/null; then
        echo "Uninstalling Snap..."
        systemctl stop snapd.service snapd.socket
        systemctl disable snapd.service snapd.socket
        apt purge snapd -y
        rm -rf /var/cache/snapd /var/snap /snap ~/snap
        apt purge gnome-software-plugin-snap -y
        apt autoremove -y
        echo "snapd hold" | dpkg --set-selections
        log "Snap uninstalled."
    else
        echo "Snap is not installed."
    fi
}

check_root
check_bash
check_ubuntu
check_apt

# Checks passed
echo "All checks have passed, proceeding..."

perform_updates
uninstall_snap

# Confirm script is finished
echo "The setup has finished..."
log "Script finished."
exit 0
