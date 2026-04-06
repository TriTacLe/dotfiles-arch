#!/bin/bash
grim -g "$(slurp)" - | wl-copy
notify-send -t 3000 "Screenshot" "Copied to clipboard"

