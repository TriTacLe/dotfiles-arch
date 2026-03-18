#!/bin/bash
# Elegant confirmation before closing window

WINDOW_CLASS=$(hyprctl activewindow -j | jq -r '.class')
WINDOW_TITLE=$(hyprctl activewindow -j | jq -r '.title' | cut -c1-40)

# If empty, use class name
if [ -z "$WINDOW_TITLE" ] || [ "$WINDOW_TITLE" = "null" ]; then
    WINDOW_TITLE="$WINDOW_CLASS"
fi

# Show elegant wofi dialog (kun popup, ingen varsling)
CHOICE=$(echo -e "✓ Close window\n✗ Keep open" | wofi \
    --dmenu \
    --prompt "Close $WINDOW_CLASS?" \
    --width 350 \
    --height 150 \
    --cache-file /dev/null \
    --insensitive \
    --matching fuzzy)

if [[ "$CHOICE" == *"Close"* ]]; then
    hyprctl dispatch killactive
fi
