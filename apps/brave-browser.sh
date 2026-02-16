#!/bin/bash

# Brave Browser installer for Omarchy

set -e

echo "Installing Brave Browser..."

# Check if already installed
if command -v brave-browser &> /dev/null; then
    echo "Brave Browser is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    
    # Install brave-browser from AUR or official repo
    if command -v yay &> /dev/null; then
        yay -S --noconfirm brave-bin
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm brave-bin
    else
        sudo pacman -S --noconfirm brave
    fi
    
elif command -v apt &> /dev/null; then
    # Debian/Ubuntu-based
    echo "Detected Debian/Ubuntu-based system"
    
    sudo apt install -y curl
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install -y brave-browser
    
elif command -v dnf &> /dev/null; then
    # Fedora-based
    echo "Detected Fedora-based system"
    
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y brave-browser
    
else
    echo "Unsupported package manager. Please install Brave manually."
    exit 1
fi

echo "Brave Browser installed successfully!"
