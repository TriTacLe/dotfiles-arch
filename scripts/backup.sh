#!/bin/bash

# =============================================================================
# Dotfiles Backup Script
# =============================================================================
# Backs up current dotfiles before making changes
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}Creating backup...${NC}"
echo "Backup location: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Files to backup
files=(
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.gitconfig"
    "$HOME/.p10k.zsh"
)

# Directories to backup
dirs=(
    "$HOME/.config/nvim"
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/ghostty"
    "$HOME/.config/alacritty"
    "$HOME/.config/kitty"
    "$HOME/.config/fastfetch"
    "$HOME/.config/wofi"
    "$HOME/.config/zsh"
)

# Backup files
echo -e "${BLUE}Backing up files...${NC}"
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        cp -v "$file" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Backup directories
echo -e "${BLUE}Backing up directories...${NC}"
for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        cp -rv "$dir" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Create tarball
echo -e "${BLUE}Creating archive...${NC}"
cd "$HOME/.dotfiles-backup"
tar -czf "$(basename "$BACKUP_DIR").tar.gz" "$(basename "$BACKUP_DIR")"
rm -rf "$(basename "$BACKUP_DIR")"

echo -e "${GREEN}Backup complete!${NC}"
echo "Archive: $HOME/.dotfiles-backup/$(basename "$BACKUP_DIR").tar.gz"
