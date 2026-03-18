#!/bin/bash
# Screenshot triggered by ASUS screenshot key (keycode 239)
grim -g "$(slurp)" - | wl-copy
notify-send -t 3000 "Screenshot" "Copied to clipboard"
