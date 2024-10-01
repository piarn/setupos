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

check_arch() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
            echo "Arch/Manjaro detected..."
        else
            echo "This script is not running on Arch or Manjaro."
            exit 1
        fi
    else
        echo "Unable to determine the OS."
        exit 1
    fi
}

check_pacman() {
    if command -v pacman > /dev/null; then
        echo "Pacman package manager found..."
    else
        echo "This system does not use Pacman as the package manager. Exiting."
        exit 1
    fi
}

perform_updates() {
    echo "Updating the system package list..."
    if pacman -Syu --noconfirm > /dev/null 2>&1; then
        log "System package list updated."
    else
        log "Failed to update package list."
        exit 1
    fi

    echo "Cleaning up unused packages..."
    pacman -Rns $(pacman -Qdtq) --noconfirm > /dev/null 2>&1
    log "Unused packages removed."
}

uninstall_snap() {
    if command -v snap &> /dev/null; then
        echo "Uninstalling Snap..."
        systemctl stop snapd.service snapd.socket
        systemctl disable snapd.service snapd.socket
        pacman -Rsn snapd --noconfirm
        rm -rf /var/cache/snapd /var/snap /snap ~/snap
        echo "snapd hold" | dpkg --set-selections  # This line might not apply to Arch.
        log "Snap uninstalled."
    else
        echo "Snap is not installed."
    fi
}

check_root
check_bash
check_arch
check_pacman

# Checks passed
echo "All checks have passed, proceeding..."

perform_updates
uninstall_snap

# Confirm script is finished
echo "The setup has finished..."
log "Script finished."
exit 0
