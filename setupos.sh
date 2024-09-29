#!/bin/bash

# Check if the script is running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Please run it with sudo or as the root user."
  exit 1
fi

#### 1. **Prompt for Hostname**
read -p "Enter the desired hostname for this system: " HOSTNAME

# Set the hostname
echo "Setting the hostname to $HOSTNAME..."
hostnamectl set-hostname "$HOSTNAME"
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

#### 2. **Set Timezone to Europe/Vilnius**

echo "Setting the timezone to Europe/Vilnius..."
timedatectl set-timezone Europe/Vilnius

#### 3. **Update & Upgrade System**

echo "Updating package lists and upgrading the system..."
apt update && apt upgrade -y && apt dist-upgrade -y

#### 4. **Debloat Ubuntu**

echo "Removing unnecessary packages and bloat..."
apt purge -y popularity-contest ubuntu-web-launchers apport whoopsie unattended-upgrades

# Remove extra language packs (optional)
apt purge -y `dpkg -l | grep "language-pack" | awk '{print $2}'`

# Clean up after package removal
apt autoremove -y
apt clean

#### 5. **Remove Snap & Install Flatpak (Optional)**

echo "Removing Snap and switching to Flatpak..."

# Remove Snap and all Snap packages
snap list | awk '{print $1}' | xargs sudo snap remove --purge
apt purge -y snapd

# Prevent Snap from being reinstalled
cat <<EOF | sudo tee /etc/apt/preferences.d/no-snap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

# Clean up Snap directories
rm -rf ~/snap /var/cache/snapd /var/snap /var/lib/snapd

# Install Flatpak (optional)
apt install -y flatpak

# Add Flathub as a source for Flatpak apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#### 6. **Install Base System Packages**

echo "Installing essential base system packages..."
apt install -y build-essential curl wget git htop neofetch vim nano \
    software-properties-common net-tools apt-transport-https ca-certificates \
    gnupg2 lsb-release dnsutils traceroute iftop python3 python3-pip \
    golang rustc qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

#### 7. **Install and Configure Zsh**

echo "Installing and configuring Zsh..."

# Install Zsh
apt install -y zsh

# Install Oh My Zsh non-interactively
echo "Installing Oh My Zsh..."
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Set Zsh as the default shell for the current user
chsh -s $(which zsh)

# Optional: Install additional Zsh plugins or themes if needed
# Install Powerlevel10k theme for Zsh
echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Set Powerlevel10k as the default theme in .zshrc
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# You can also install useful Zsh plugins like fzf, syntax-highlighting, etc.:
echo "Installing useful Zsh plugins..."

# Zsh Syntax Highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "source ${(q-)ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

# Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
echo "source ${(q-)ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc

#### 8. **Set Up Basic Firewall (Optional)**

echo "Setting up the firewall with basic rules..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

#### 9. **Clean Up**

echo "Cleaning up any unnecessary files..."
apt autoremove -y
apt clean

#### 10. **Final Message**

echo "System setup complete! Rebooting is recommended. If you are using Zsh, it will take effect after logout and login, or after a reboot."
