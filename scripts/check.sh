#!/bin/bash

# =============================================================================
# Dotfiles Check Script
# =============================================================================
# Checks the status of dotfiles installation
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_symlink() {
    local src="$1"
    local expected="$2"
    
    if [[ -L "$src" ]]; then
        local target=$(readlink -f "$src")
        if [[ "$target" == "$expected"* ]]; then
            echo -e "${GREEN}✓${NC} $src"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} $src -> $target (unexpected target)"
            return 1
        fi
    elif [[ -e "$src" ]]; then
        echo -e "${RED}✗${NC} $src (not a symlink)"
        return 1
    else
        echo -e "${RED}✗${NC} $src (missing)"
        return 1
    fi
}

check_package() {
    local pkg="$1"
    if pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $pkg"
        return 0
    else
        echo -e "${RED}✗${NC} $pkg (not installed)"
        return 1
    fi
}

echo -e "${BLUE}Dotfiles Status Check${NC}"
echo "======================"
echo ""

# Check stow packages
echo -e "${BLUE}Stow Packages:${NC}"
cd "$DOTFILES_DIR"

packages=(
    "zsh:.zshrc"
    "nvim:.config/nvim"
    "tmux:.tmux.conf"
    "git:.gitconfig"
    "hypr:.config/hypr"
    "waybar:.config/waybar"
    "ghostty:.config/ghostty"
    "alacritty:.config/alacritty"
    "kitty:.config/kitty"
    "fastfetch:.config/fastfetch"
    "wofi:.config/wofi"
    "starship:.config/starship.toml"
)

stowed=0
not_stowed=0

for pkg_info in "${packages[@]}"; do
    IFS=':' read -r pkg path <<< "$pkg_info"
    if [[ -L "$HOME/$path" ]]; then
        if readlink -f "$HOME/$path" | grep -q "$DOTFILES_DIR/$pkg"; then
            echo -e "  ${GREEN}✓${NC} $pkg"
            ((stowed++))
        else
            echo -e "  ${YELLOW}⚠${NC} $pkg (different source)"
            ((not_stowed++))
        fi
    else
        echo -e "  ${RED}✗${NC} $pkg (not stowed)"
        ((not_stowed++))
    fi
done

echo ""
echo -e "${BLUE}Essential Packages:${NC}"

# Check essential packages
essential_pkgs=(
    "zsh"
    "nvim"
    "tmux"
    "git"
    "fzf"
    "eza"
    "bat"
    "zoxide"
    "starship"
    "hyprland"
    "waybar"
    "ghostty"
    "yay"
)

installed=0
not_installed=0

for pkg in "${essential_pkgs[@]}"; do
    if command -v pacman &>/dev/null && pacman -Q "$pkg" &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $pkg"
        ((installed++))
    elif command -v yay &>/dev/null && yay -Q "$pkg" &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $pkg"
        ((installed++))
    elif command -v "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg"
        ((installed++))
    else
        echo -e "  ${RED}✗${NC} $pkg"
        ((not_installed++))
    fi
done

echo ""
echo -e "${BLUE}Services:${NC}"

# Check services
services=(
    "NetworkManager"
    "bluetooth"
    "sddm"
    "docker"
)

for svc in "${services[@]}"; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        if systemctl is-active "$svc" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $svc (enabled & active)"
        else
            echo -e "  ${YELLOW}⚠${NC} $svc (enabled but inactive)"
        fi
    else
        echo -e "  ${RED}✗${NC} $svc (not enabled)"
    fi
done

echo ""
echo -e "${BLUE}Shell:${NC}"
if [[ "$SHELL" == *"zsh"* ]]; then
    echo -e "  ${GREEN}✓${NC} zsh is default shell"
else
    echo -e "  ${RED}✗${NC} zsh is not default (current: $SHELL)"
fi

echo ""
echo "======================"
echo -e "Stowed packages: ${GREEN}$stowed${NC}, Not stowed: ${RED}$not_stowed${NC}"
echo -e "Installed packages: ${GREEN}$installed${NC}, Missing: ${RED}$not_installed${NC}"
echo ""

if [[ $not_stowed -eq 0 && $not_installed -eq 0 ]]; then
    echo -e "${GREEN}All checks passed! ✓${NC}"
    exit 0
else
    echo -e "${YELLOW}Some items need attention.${NC}"
    echo "Run './install.sh' to fix issues."
    exit 1
fi
