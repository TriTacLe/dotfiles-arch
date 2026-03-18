#!/bin/bash
# Ask for confirmation before killing active window

WINDOW=$(hyprctl activewindow -j | jq -r '.title')
CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    WINDOW="Unknown"
fi

# Show confirmation dialog
ANSWER=$(echo -e "Yes\nNo" | wofi --dmenu --prompt "Close $CLASS?" --width 300 --height 150)

if [ "$ANSWER" = "Yes" ]; then
    hyprctl dispatch killactive
fi
