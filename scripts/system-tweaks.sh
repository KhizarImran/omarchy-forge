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

echo "System tweaks applied!"
