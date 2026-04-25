##!/bin/bash

# Brightness control with avizo (macOS-style center overlay with icons)
# Usage: brightness_avizo.sh [up|down]

ACTION="$1"

# Ensure avizo-daemon is running
if ! pgrep -x "avizo-daemon" > /dev/null; then
  avizo-daemon &
  sleep 0.2
fi

# Execute the action
case "$ACTION" in
  up)
    brightnessctl set 5%+ 2>/dev/null
    sleep 0.05
    lightctl up
    ;;
  down)
    brightnessctl set 5%- 2>/dev/null
    sleep 0.05
    lightctl down
    ;;
esac
