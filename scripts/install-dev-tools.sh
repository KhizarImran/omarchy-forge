#!/bin/bash

# Install common development tools

echo "Installing development tools..."

# Detect package manager and install tools
if command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm --needed \
        base-devel \
        curl \
        wget \
        htop \
        ripgrep \
        fd \
        bat \
        eza
        
elif command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y \
        build-essential \
        curl \
        wget \
        htop \
        ripgrep \
        fd-find \
        bat
        
elif command -v dnf &> /dev/null; then
    sudo dnf install -y \
        @development-tools \
        curl \
        wget \
        htop \
        ripgrep \
        fd-find \
        bat
fi

echo "Development tools installed!"
