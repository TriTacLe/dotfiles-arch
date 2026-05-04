#!/bin/bash

# macOS-style screenshot med preview og auto-lagring

# Lag midlertidig fil
TMP_FILE="/tmp/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
SAVE_DIR="$HOME/Pictures/Screenshots"

# Screenshot til midlertidig fil
grim -g "$(slurp)" "$TMP_FILE"

# Kopier til clipboard umiddelbart (kan paste med Ctrl+V)
wl-copy < "$TMP_FILE"

# Vis notifikasjon med preview
notify-send -i "$TMP_FILE" -t 5000 "Screenshot tatt" "Bilde kopiert til clipboard"

# Lagre til permanent lokasjon
mkdir -p "$SAVE_DIR"
FINAL_FILE="$SAVE_DIR/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
mv "$TMP_FILE" "$FINAL_FILE"

notify-send -t 3000 "Screenshot lagret" "$FINAL_FILE"
