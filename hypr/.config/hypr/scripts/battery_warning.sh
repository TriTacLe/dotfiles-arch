#!/bin/bash

if ! upower -e | grep -q "battery"; then
  exit 0
fi

BATTERY_PATH=$(upower -e | grep battery | head -1)
BATTERY_PERCENT=$(upower -i "$BATTERY_PATH" | grep percentage | awk '{print $2}' | tr -d '%')
BATTERY_STATE=$(upower -i "$BATTERY_PATH" | grep state | awk '{print $2}')

if [ "$BATTERY_STATE" = "discharging" ]; then
  if [ "$BATTERY_PERCENT" -le 5 ]; then
    notify-send -u critical "Kun $BATTERY_PERCENT% igjen!"
  elif [ "$BATTERY_PERCENT" -le 10 ]; then
    notify-send -u critical "Batteri lavt: $BATTERY_PERCENT%"
  elif [ "$BATTERY_PERCENT" -le 20 ]; then
    notify-send -u normal "Batteri: $BATTERY_PERCENT%"
  fi
fi
