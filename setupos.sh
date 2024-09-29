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
  apt purge -y `dpkg -l | grep "language-pack" | awk '{print $2}'`
  apt autoremove -y
  apt clean
}

# Function to remove Snap and install Flatpak
replace_snap_with_flatpak() {
  read -p "Do you want to remove Snap and install Flatpak instead? (y/n): " CONFIRM
  if [[ "$CONFIRM" == "y" ]]; then
    echo "Removing Snap and switching to Flatpak..."

    # Remove Snap and all Snap packages
    snap list | awk '{print $1}' | xargs snap remove --purge || true
    apt purge -y snapd

    # Prevent Snap from being reinstalled
    cat <<EOF | tee /etc/apt/preferences.d/no-snap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

    # Clean up Snap directories
    rm -rf ~/snap /var/cache/snapd /var/snap /var/lib/snapd

    # Install Flatpak
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

# Function to install base system packages
install_base_packages() {
  echo "Installing essential base system packages..."
  apt install -y build-essential curl wget git htop neofetch vim nano \
      software-properties-common net-tools apt-transport-https ca-certificates \
      gnupg2 lsb-release dnsutils traceroute iftop python3 python3-pip \
      golang rustc qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
}

# Function to install and configure Zsh
install_zsh() {
  echo "Installing and configuring Zsh..."
  apt install -y zsh

  # Install Oh My Zsh non-interactively
  echo "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

  # Set Zsh as the default shell for the current user
  chsh -s $(which zsh)

  # Install Powerlevel10k theme for Zsh
  echo "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

  # Install Zsh Syntax Highlighting
  echo "Installing useful Zsh plugins..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  echo "source ${(q-)ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

  # Install Zsh Autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  echo "source ${(q-)ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
}

# Function to set up a basic firewall
setup_firewall() {
  echo "Setting up the firewall with basic rules..."
  apt install -y ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  ufw enable
}

# Function to clean up the system
clean_up_system() {
  echo "Cleaning up any unnecessary files..."
  apt autoremove -y
  apt clean
}

# Main execution block
set_hostname
set_timezone
update_system
debloat_system
replace_snap_with_flatpak
install_base_packages
install_zsh
setup_firewall
clean_up_system

echo "System setup complete! Rebooting is recommended. If you are using Zsh, it will take effect after logout and login, or after a reboot."
