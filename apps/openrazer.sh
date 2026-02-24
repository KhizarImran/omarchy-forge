#!/bin/bash

# OpenRazer installer for Omarchy
# Installs openrazer-daemon and python-openrazer for Razer keyboard RGB control

set -e

echo "Installing OpenRazer (Razer hardware RGB support)..."

# Check if already installed and daemon enabled
if python3 -c "import openrazer" &> /dev/null && systemctl --user is-enabled openrazer-daemon &> /dev/null; then
    echo "OpenRazer is already installed and enabled"
    exit 0
fi

if command -v pacman &> /dev/null; then
    echo "Detected Arch-based system"

    # openrazer-daemon and python-openrazer are AUR packages on Arch
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed openrazer-daemon python-openrazer
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm --needed openrazer-daemon python-openrazer
    else
        echo "ERROR: yay or paru required to install AUR packages (openrazer-daemon, python-openrazer)"
        echo "Install yay first: https://github.com/Jguer/yay"
        exit 1
    fi

elif command -v apt &> /dev/null; then
    echo "Detected Debian/Ubuntu-based system"
    sudo add-apt-repository ppa:openrazer/stable -y
    sudo apt update
    sudo apt install -y openrazer-daemon python3-openrazer

elif command -v dnf &> /dev/null; then
    echo "Detected Fedora-based system"
    sudo dnf install -y openrazer-daemon python3-openrazer

else
    echo "Unsupported package manager. Please install openrazer-daemon and python-openrazer manually."
    exit 1
fi

# Add current user to openrazer group (required for OpenRazer hardware access)
# Note: on Arch, OpenRazer uses the 'openrazer' group, not 'plugdev'
if ! groups "$USER" | grep -q openrazer; then
    echo "Adding $USER to openrazer group..."
    sudo gpasswd -a "$USER" openrazer
    echo "NOTE: You must log out and back in for group membership to take effect"
fi

# Enable and start the openrazer daemon
echo "Enabling openrazer-daemon service..."
systemctl --user enable openrazer-daemon
systemctl --user start openrazer-daemon || echo "Note: openrazer-daemon will start on next login if not running now"

echo "OpenRazer installed successfully!"
echo "If this is a fresh install, please log out and back in for hardware access (openrazer group)."
