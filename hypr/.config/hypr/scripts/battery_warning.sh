#!/bin/bash

if ! upower -e | grep -q "battery"; then
  exit 0
fi

BATTERY_PATH=$(upower -e | grep battery | head -1)
BATTERY_PERCENT=$(upower -i "$BATTERY_PATH" | grep percentage | awk '{print $2}' | tr -d '%')
BATTERY_STATE=$(upower -i "$BATTERY_PATH" | grep state | awk '{print $2}')

# File to track if we've already dimmed the screen
DIMMED_FLAG="/tmp/battery_dimmed"
# File to store original brightness
BRIGHTNESS_FILE="/tmp/battery_original_brightness"

if [ "$BATTERY_STATE" = "discharging" ]; then
  if [ "$BATTERY_PERCENT" -le 5 ]; then
    notify-send -u critical "Kun $BATTERY_PERCENT% igjen!"
    # Dim screen to minimum if not already dimmed
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl g > "$BRIGHTNESS_FILE"
      brightnessctl set 5%
      touch "$DIMMED_FLAG"
    fi
  elif [ "$BATTERY_PERCENT" -le 10 ]; then
    notify-send -u critical "Batteri lavt: $BATTERY_PERCENT%"
    # Dim screen if not already dimmed
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl g > "$BRIGHTNESS_FILE"
      brightnessctl set 15%
      touch "$DIMMED_FLAG"
    fi
  elif [ "$BATTERY_PERCENT" -le 20 ]; then
    notify-send -u normal "Batteri: $BATTERY_PERCENT%"
    # Slightly dim screen if not already dimmed
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl g > "$BRIGHTNESS_FILE"
      brightnessctl set 30%
      touch "$DIMMED_FLAG"
    fi
  fi
else
  # Charging or fully charged - restore brightness if we dimmed it
  if [ -f "$DIMMED_FLAG" ]; then
    if [ -f "$BRIGHTNESS_FILE" ]; then
      ORIGINAL=$(cat "$BRIGHTNESS_FILE")
      brightnessctl set "$ORIGINAL"
      rm "$BRIGHTNESS_FILE"
    fi
    rm "$DIMMED_FLAG"
    notify-send -u normal "Lader... Lysstyrke gjenopprettet"
  fi
fi
