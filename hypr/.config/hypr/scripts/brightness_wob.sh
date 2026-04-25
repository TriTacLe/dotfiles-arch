#!/bin/bash

# Brightness control with wob (macOS-style center overlay)
# Usage: brightness_wob.sh [up|down]

ACTION="$1"
WOBSOCK="$XDG_RUNTIME_DIR/wob.sock"

# Ensure wob socket exists
if [ ! -e "$WOBSOCK" ]; then
  # Try to start wob if not running
  wob -c ~/.config/wob/wob.ini &
  sleep 0.1
fi

# Check if brightnessctl is available
if ! command -v brightnessctl &> /dev/null; then
  notify-send -u critical "Error" "brightnessctl not found"
  exit 1
fi

# Get current brightness percentage
get_brightness_percent() {
  current=$(brightnessctl g 2>/dev/null)
  max=$(brightnessctl m 2>/dev/null)
  if [ -n "$current" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
    echo $((current * 100 / max))
  else
    echo "0"
  fi
}

# Execute the action
case "$ACTION" in
  up)
    brightnessctl set 5%+ 2>/dev/null
    ;;
  down)
    brightnessctl set 5%- 2>/dev/null
    ;;
esac

# Get updated brightness
BRIGHTNESS=$(get_brightness_percent)

# Send to wob
echo "$BRIGHTNESS" > "$WOBSOCK" 2>/dev/null
