#!/bin/bash

# Volume control with wob (macOS-style center overlay)
# Usage: volume_wob.sh [up|down|mute]

ACTION="$1"
WOBSOCK="$XDG_RUNTIME_DIR/wob.sock"

# Ensure wob socket exists
if [ ! -e "$WOBSOCK" ]; then
  # Try to start wob if not running
  wob -c ~/.config/wob/wob.ini &
  sleep 0.1
fi

# Get current volume info
get_volume() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null
}

# Get volume percentage (0-100)
get_volume_percent() {
  vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP '[0-9]+\.[0-9]+' | head -1)
  if [ -n "$vol" ]; then
    echo "$(echo "$vol * 100" | bc | cut -d. -f1)"
  else
    echo "0"
  fi
}

# Check if muted
is_muted() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"
}

# Execute the action
case "$ACTION" in
  up)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    ;;
  down)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
esac

# Get updated volume
VOLUME=$(get_volume_percent)

# Handle muted state - show 0 when muted
if is_muted; then
  VOLUME=0
fi

# Send to wob (format: "volume%" or "volume% overflow")
echo "$VOLUME" > "$WOBSOCK" 2>/dev/null
