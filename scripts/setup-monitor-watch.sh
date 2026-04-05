#!/bin/bash

# Sets up a monitor-watch daemon that auto-reloads Hyprland config
# when monitors are unplugged, so positioning resets correctly.

SCRIPTS_DIR="$HOME/.config/hypr/scripts"
WATCH_SCRIPT="$SCRIPTS_DIR/monitor-watch.sh"
AUTOSTART="$HOME/.config/hypr/autostart.conf"

echo "Setting up monitor-watch..."

mkdir -p "$SCRIPTS_DIR"

cat > "$WATCH_SCRIPT" << 'EOF'
#!/bin/bash
# Reload Hyprland config when a monitor is removed
socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ "$line" == monitorremoved* ]]; then
        hyprctl reload
    fi
done
EOF

chmod +x "$WATCH_SCRIPT"

if ! grep -q "monitor-watch.sh" "$AUTOSTART" 2>/dev/null; then
    echo "exec-once = ~/.config/hypr/scripts/monitor-watch.sh" >> "$AUTOSTART"
    echo "Added monitor-watch to autostart"
else
    echo "monitor-watch already in autostart, skipping"
fi

echo "Monitor-watch setup complete"
