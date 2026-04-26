#!/bin/bash
# Dotfiles Configuration - Centralized for easy multi-PC management
# Edit this file for customization instead of scripts

# ============================================
# PATH CONFIGURATION
# ============================================

# Default dotfiles location (auto-detected if not set)
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Desktop/dotfiles}"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# Machine-specific overrides (uncomment and customize per PC)
case "${HOSTNAME:-$(hostname)}" in
    production-pc)
        DOTFILES_DIR="$HOME/dotfiles"
        ;;
    your-laptop)
        DOTFILES_DIR="$HOME/.dotfiles"
        ;;
    # Add more PC-specific overrides here
esac

# ============================================
# MACHINE IDENTIFICATION
# ============================================

# Override machine detection if needed
MACHINE_TYPE="${MACHINE_TYPE:-auto}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-master}"

# ============================================
# PACKAGE CATEGORIES
# ============================================

# Customizable package patterns per category
CATEGORIES=(
    "aur:AUR packages|yay -Qi"
    "development:Development tools|docker|git|node|python|go|java|rust|cmake|clang|build|devel"
    "desktop:Desktop environment|hypr|waybar|wofi|sway|pk|xdg|kde|gnome|plasma"
    "terminal:Terminal utilities|vim|nvim|tmux|fzf|eza|bat|starship|zsh|shell|term"
    "applications:User applications|firefox|brave|chrom|slack|spotify|obsidian|libreoffice|code|ide"
    "core:Essential system packages|"
)

# ============================================
# GIT CONFIGURATION
# ============================================

# Auto-push settings
AUTO_PUSH="${AUTO_PUSH:-true}"
AUTO_PUSH_REQUIRE_GH="${AUTO_PUSH_REQUIRE_GH:-true}"

# ============================================
# EXPORT VARIABLES
# ============================================

export DOTFILES_DIR
export PACKAGES_DIR
export MACHINE_TYPE
export GIT_REMOTE
export GIT_BRANCH
export AUTO_PUSH
export AUTO_PUSH_REQUIRE_GH

# echo "Config loaded: $DOTFILES_DIR"  # Debug
