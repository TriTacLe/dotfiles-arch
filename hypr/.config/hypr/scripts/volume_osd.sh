#!/bin/bash

# Volume OSD script with progress bar
# Usage: volume_osd.sh [up|down|mute]

ACTION="$1"

# Get current volume info
get_volume() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null
}

# Get mute status
is_muted() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"
}

# Get volume percentage
get_volume_percent() {
  vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP '[0-9]+\.[0-9]+' | head -1)
  if [ -n "$vol" ]; then
    echo "$(echo "$vol * 100" | bc | cut -d. -f1)"
  else
    echo "0"
  fi
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

# Choose icon based on volume level and mute status
if is_muted; then
  ICON="󰖁"
  TEXT="Muted"
else
  if [ "$VOLUME" -eq 0 ]; then
    ICON="󰖁"
  elif [ "$VOLUME" -le 30 ]; then
    ICON="󰕿"
  elif [ "$VOLUME" -le 60 ]; then
    ICON="󰖀"
  else
    ICON="󰕾"
  fi
  TEXT="${VOLUME}%"
fi

# Create progress bar (20 segments)
BAR_LENGTH=20
FILLED=$((VOLUME * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))

# Build the bar
BAR=""
for ((i=0; i<FILLED; i++)); do
  BAR="${BAR}█"
done
for ((i=0; i<EMPTY; i++)); do
  BAR="${BAR}░"
done

# Send notification with progress bar (using swaync with hints for progress)
# Using notify-send with hints for progress display
notify-send -u low -h "int:value:$VOLUME" -h "string:x-canonical-private-synchronous:volume" "$ICON Volume" "$BAR  $TEXT"
