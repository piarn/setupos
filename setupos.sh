#!/bin/bash

# Stop on any error
set -e

# Check if the script is running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Please run it with sudo or as the root user."
  exit 1
fi

# Function to set hostname
set_hostname() {
  read -p "Enter the desired hostname for this system: " HOSTNAME
  echo "Setting the hostname to $HOSTNAME..."
  hostnamectl set-hostname "$HOSTNAME"
  # Ensure hostname is added to /etc/hosts
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
}

# Function to set timezone
set_timezone() {
  echo "Setting the timezone to Europe/Vilnius..."
  timedatectl set-timezone Europe/Vilnius
}

# Function to update and upgrade the system
update_system() {
  echo "Updating package lists and upgrading the system..."
  apt update && apt upgrade -y && apt dist-upgrade -y
}

# Function to debloat the system
debloat_system() {
  echo "Removing unnecessary packages and bloat..."
  apt purge -y popularity-contest ubuntu-web-launchers apport whoopsie unattended-upgrades
  
  # Remove Snap and all Snap packages
  if command -v snap &> /dev/null; then
    echo "Removing Snap and all installed Snap packages..."
    snap list | awk '{print $1}' | xargs -r snap remove --purge || true
    apt purge -y snapd

    # Prevent Snap from being reinstalled
    cat <<EOF | tee /etc/apt/preferences.d/no-snap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

    # Clean up Snap directories
    rm -rf ~/snap /var/cache/snapd /var/snap /var/lib/snapd
  else
    echo "Snap is not installed."
  fi

  # Clean up unnecessary language packs
  apt purge -y `dpkg -l | grep "language-pack" | awk '{print $2}'` || true

  # Clean up after package removal
  apt autoremove -y
  apt clean
}

# Function to install base system packages
install_base_packages() {
  echo "Installing essential base system packages..."
  apt install -y build-essential curl wget git htop neofetch vim nano \
      software-properties-common net-tools apt-transport-https ca-certificates \
      gnupg2 lsb-release dnsutils traceroute iftop python3 python3-pip \
      golang rustc qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
}

# Main execution block
set_hostname
set_timezone
update_system
debloat_system
install_base_packages

echo "System setup complete! Rebooting is recommended."
