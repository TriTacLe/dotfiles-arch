#!/bin/bash

# Brightness OSD script with progress bar
# Usage: brightness_osd.sh [up|down]

ACTION="$1"

# Check if brightnessctl is available
if ! command -v brightnessctl &> /dev/null; then
  notify-send -u critical "Error" "brightnessctl not found"
  exit 1
fi

# Get current brightness info
get_brightness_percent() {
  brightnessctl i | grep -oP '\d+(?=%)' | head -1
}

# Get max brightness
get_max_brightness() {
  brightnessctl m 2>/dev/null || echo "100"
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

# Handle case where brightness detection fails
if [ -z "$BRIGHTNESS" ]; then
  BRIGHTNESS=0
fi

# Choose icon based on brightness level
if [ "$BRIGHTNESS" -eq 0 ]; then
  ICON="󰃚"
elif [ "$BRIGHTNESS" -le 30 ]; then
  ICON="󰃛"
elif [ "$BRIGHTNESS" -le 60 ]; then
  ICON="󰃜"
else
  ICON="󰃠"
fi

# Create progress bar (20 segments)
BAR_LENGTH=20
FILLED=$((BRIGHTNESS * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))

# Build the bar
BAR=""
for ((i=0; i<FILLED; i++)); do
  BAR="${BAR}█"
done
for ((i=0; i<EMPTY; i++)); do
  BAR="${BAR}░"
done

# Send notification with progress bar
notify-send -u low -h "int:value:$BRIGHTNESS" -h "string:x-canonical-private-synchronous:brightness" "$ICON Brightness" "$BAR  ${BRIGHTNESS}%"
