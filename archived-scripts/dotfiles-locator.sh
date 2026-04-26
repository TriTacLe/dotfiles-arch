#!/bin/bash
# Dotfiles Location Management
# This script provides location info for other scripts

# Common dotfiles locations in priority order
DOTFILES_LOCATIONS=(
    "$HOME/Desktop/dotfiles"
    "$HOME/dotfiles"
    "$HOME/.dotfiles"
    "$HOME/Documents/dotfiles"
)

# Auto-detect dotfiles location
find_dotfiles_dir() {
    # First check if DOTFILES_DIR is set
    if [[ -n "${DOTFILES_DIR:-}" ]]; then
        if [[ -d "$DOTFILES_DIR" && -f "$DOTFILES_DIR/install.sh" ]]; then
            echo "$DOTFILES_DIR"
            return 0
        fi
    fi

    # Search common locations
    for location in "${DOTFILES_LOCATIONS[@]}"; do
        if [[ -d "$location" && -f "$location/install.sh" ]]; then
            echo "$location"
            return 0
        fi
    done

    # Not found
    return 1
}

# Get dotfiles directory (with error handling)
get_dotfiles_dir() {
    local dotfiles_dir
    dotfiles_dir=$(find_dotfiles_dir)
    
    if [[ -z "$dotfiles_dir" ]]; then
        echo "ERROR: Dotfiles directory not found!" >&2
        echo "Please ensure dotfiles are in one of:" >&2
        echo "  - ~/Desktop/dotfiles" >&2
        echo "  - ~/dotfiles" >&2
        echo "  - ~/.dotfiles" >&2
        return 1
    fi

    echo "$dotfiles_dir"
    return 0
}

# Export dotfiles directory for other scripts
if [[ "${1:-}" == "export" ]]; then
    DOTFILES_DIR=$(get_dotfiles_dir) || exit 1
    echo "$DOTFILES_DIR"
fi