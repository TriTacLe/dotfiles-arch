#!/bin/bash
# Wallpaper slideshow - rotates every 30 minutes

WALLPAPER_DIR="$HOME/.config/backgrounds"
SPLITTER_DIR="$HOME/.config/hypr/scripts/WallpaperSplitter"
INTERVAL=1800

# Wait for hyprpaper to be ready
sleep 2

# Build list of wallpapers
WALLPAPERS=()
for wp in "$SPLITTER_DIR"/*.png "$SPLITTER_DIR"/*.jpg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.jpg; do
    [[ -f "$wp" ]] && WALLPAPERS+=("$wp")
done

# Check if we have wallpapers
if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "No wallpapers found"
    exit 1
fi

# Get monitors
get_monitors() {
    hyprctl monitors | grep "Monitor" | awk '{print $2}'
}

# Set wallpapers
set_wallpapers() {
    mapfile -t monitors < <(get_monitors)
    
    [[ ${#monitors[@]} -eq 0 ]] && return
    
    hyprctl hyprpaper unload all 2>/dev/null
    
    for monitor in "${monitors[@]}"; do
        wallpaper=${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}
        hyprctl hyprpaper wallpaper "$monitor,$wallpaper" 2>/dev/null
    done
}

# Set immediately
set_wallpapers

# Loop
while true; do
    sleep $INTERVAL
    set_wallpapers
done
