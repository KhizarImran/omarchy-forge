#!/bin/bash

# System tweaks and optimizations for Omarchy

echo "Applying system tweaks..."

# Example tweaks - customize as needed

# Increase file watchers (useful for development)
if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf 2>/dev/null; then
    echo "Increasing inotify watchers..."
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Set swappiness (reduce swap usage on systems with plenty of RAM)
if ! grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
    echo "Setting swappiness to 10..."
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Reverse touchpad scrolling (natural scrolling)
echo "Setting up natural touchpad scrolling..."
TOUCHPAD_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$TOUCHPAD_CONFIG" ]; then
    # Check if touchpad input config exists
    if ! grep -q "natural_scroll.*=.*yes" "$TOUCHPAD_CONFIG"; then
        # Add or update touchpad natural scroll setting
        if grep -q "device.*touchpad" "$TOUCHPAD_CONFIG" -A 5; then
            # Touchpad section exists, update it
            sed -i '/device.*touchpad/,/}/ s/natural_scroll.*/    natural_scroll = yes/' "$TOUCHPAD_CONFIG"
        else
            # Add touchpad configuration
            cat >> "$TOUCHPAD_CONFIG" << 'EOF'

# Touchpad configuration
input {
    touchpad {
        natural_scroll = yes
    }
}
EOF
        fi
        echo "Natural scrolling enabled - restart Hyprland or re-login to apply"
    else
        echo "Natural scrolling already enabled"
    fi
else
    echo "Hyprland config not found, skipping touchpad config"
fi

# Round corners for tiling windows
echo "Setting up rounded corners for windows..."
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    # Check if rounded corners are already configured
    if ! grep -q "rounding.*=.*[1-9]" "$HYPR_CONFIG"; then
        # Check if decoration section exists
        if grep -q "^decoration" "$HYPR_CONFIG"; then
            # Decoration section exists, add rounding if not present
            if ! grep -q "^\s*rounding" "$HYPR_CONFIG"; then
                sed -i '/^decoration {/a\    rounding = 10' "$HYPR_CONFIG"
                echo "Added rounded corners (10px) to decoration section"
            fi
        else
            # Add decoration section with rounding
            cat >> "$HYPR_CONFIG" << 'EOF'

# Window decoration
decoration {
    rounding = 10
}
EOF
            echo "Added decoration section with rounded corners (10px)"
        fi
        echo "Rounded corners enabled - restart Hyprland or re-login to apply"
    else
        echo "Rounded corners already configured"
    fi
else
    echo "Hyprland config not found, skipping rounded corners config"
fi

# Screen backlight key bindings
echo "Setting up screen backlight key bindings..."
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    # Install brightnessctl if not present
    if ! command -v brightnessctl &> /dev/null; then
        echo "Installing brightnessctl..."
        if command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm --needed brightnessctl
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y brightnessctl
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y brightnessctl
        fi
        echo "brightnessctl installed"
    fi
    
    # Check if backlight bindings already exist
    if ! grep -q "XF86MonBrightnessUp" "$HYPR_CONFIG"; then
        # Add screen backlight key bindings
        cat >> "$HYPR_CONFIG" << 'EOF'

# Screen backlight control
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF
        echo "Added screen backlight key bindings (brightness up/down)"
        echo "Screen backlight keys enabled - restart Hyprland or re-login to apply"
    else
        echo "Screen backlight key bindings already configured"
    fi
    
    # Check if keyboard backlight bindings already exist
    if ! grep -q "XF86KbdBrightnessUp" "$HYPR_CONFIG"; then
        # Add keyboard backlight key bindings
        cat >> "$HYPR_CONFIG" << 'EOF'

# Keyboard backlight control (MacBook)
bind = , XF86KbdBrightnessUp, exec, brightnessctl --device='*::kbd_backlight' set +10%
bind = , XF86KbdBrightnessDown, exec, brightnessctl --device='*::kbd_backlight' set 10%-
EOF
        echo "Added keyboard backlight key bindings"
        echo "Keyboard backlight keys enabled - restart Hyprland or re-login to apply"
    else
        echo "Keyboard backlight key bindings already configured"
    fi
else
    echo "Hyprland config not found, skipping backlight key bindings"
fi

echo "System tweaks applied!"
