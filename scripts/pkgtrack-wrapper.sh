#!/bin/bash
# Dotfiles Location Wrapper for Pacman Hook
# This wrapper ensures the hook works when running as root

# Get the actual user (not root) who ran sudo
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Auto-detect dotfiles location using common paths
DOTFILES_LOCATIONS=(
    "$HOME/Desktop/dotfiles"
    "$HOME/dotfiles"
    "$HOME/.dotfiles"
    "$HOME/Documents/dotfiles"
)

# Find dotfiles directory
DOTFILES_DIR=""
for location in "${DOTFILES_LOCATIONS[@]}"; do
    if [[ -f "$location/scripts/pkgtrack_auto.sh" ]]; then
        DOTFILES_DIR="$location"
        break
    fi
done

# If not found, try to detect from current script's location
if [[ -z "$DOTFILES_DIR" ]]; then
    SCRIPT_SOURCE="${BASH_SOURCE[0]}"
    while [[ -h "$SCRIPT_SOURCE" ]]; do
        LINK_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
        SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
        [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$LINK_DIR/$SCRIPT_SOURCE"
    done
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
fi

# Run the actual tracking script if found
if [[ -n "$DOTFILES_DIR" && -f "$DOTFILES_DIR/scripts/pkgtrack_auto.sh" ]]; then
    bash "$DOTFILES_DIR/scripts/pkgtrack_auto.sh"
fi

exit 0