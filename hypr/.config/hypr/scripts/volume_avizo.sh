#!/bin/bash

# Volume control with avizo (macOS-style center overlay with icons)
# Usage: volume_avizo.sh [up|down|mute]

ACTION="$1"

# Ensure avizo-daemon is running
if ! pgrep -x "avizo-daemon" > /dev/null; then
  avizo-daemon &
  sleep 0.2
fi

# Execute the action
case "$ACTION" in
  up)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    sleep 0.05
    volumectl -u up
    ;;
  down)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    sleep 0.05
    volumectl -u down
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    sleep 0.05
    volumectl toggle-mute
    ;;
esac
