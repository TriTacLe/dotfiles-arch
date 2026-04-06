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
notify-send -i "$TMP_FILE" -t 5000 "Screenshot tatt" "Bilde kopiert til clipboard. Auto-lagres om 5 sek..."

# Åpne i swappy for preview/redigering (valgfritt - kommenter ut hvis du ikke vil ha dette)
swappy -f "$TMP_FILE" -o "$TMP_FILE" &
SWAPPY_PID=$!

# Vent enten på at swappy lukkes ELLER 5 sekunder
( sleep 5 && kill $SWAPPY_PID 2>/dev/null ) &
wait $SWAPPY_PID 2>/dev/null

# Lagre til permanent lokasjon
mkdir -p "$SAVE_DIR"
FINAL_FILE="$SAVE_DIR/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
mv "$TMP_FILE" "$FINAL_FILE"

notify-send -t 3000 "Screenshot lagret" "$FINAL_FILE"
