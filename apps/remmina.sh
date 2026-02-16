#!/bin/bash

# Remmina RDP client installer for Omarchy

set -e

echo "Installing Remmina..."

# Check if already installed
if command -v remmina &> /dev/null; then
    echo "Remmina is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    sudo pacman -Sy --noconfirm --needed remmina freerdp libvncserver
    
elif command -v apt &> /dev/null; then
    # Debian/Ubuntu-based
    echo "Detected Debian/Ubuntu-based system"
    sudo apt update
    sudo apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc
    
elif command -v dnf &> /dev/null; then
    # Fedora-based
    echo "Detected Fedora-based system"
    sudo dnf install -y remmina remmina-plugins-rdp remmina-plugins-vnc
    
else
    echo "Unsupported package manager. Please install Remmina manually."
    exit 1
fi

echo "Remmina installed successfully!"
