#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env if exists
[[ -f "$DOTFILES_DIR/.env" ]] && source "$DOTFILES_DIR/.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[install]${NC} $1"; }
ok() { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[warn]${NC} $1"; }

# Checks
check() {
    [[ $EUID -eq 0 ]] && { echo "Don't run as root"; exit 1; }
    [[ ! -f /etc/arch-release ]] && { echo "Arch Linux only"; exit 1; }
    [[ -z "$HOME" ]] && { echo "HOME not set"; exit 1; }
    ping -c 1 -W 5 archlinux.org &>/dev/null || { echo "No internet"; exit 1; }
    sudo -v || { echo "Sudo required"; exit 1; }
}

# Install yay
install_yay() {
    command -v yay &>/dev/null && return
    log "Installing yay..."
    local tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    cd "$tmp/yay"
    makepkg -si --noconfirm
    rm -rf "$tmp"
}

# Install packages
install_packages() {
    log "Installing packages..."
    
    # Essentials
    sudo pacman -S --needed --noconfirm zsh git curl wget stow base-devel 2>/dev/null || true
    
    # From lists
    for file in packages/*.txt; do
        [[ "$file" == *"aur.txt" ]] && continue
        grep -v '^#' "$file" | grep -v '^$' | xargs -r sudo pacman -S --needed --noconfirm 2>/dev/null || true
    done
    
    # AUR
    if [[ -f "packages/aur.txt" ]] && command -v yay &>/dev/null; then
        grep -v '^#' packages/aur.txt | grep -v '^$' | xargs -r yay -S --needed --noconfirm 2>/dev/null || true
    fi
    
    ok "Packages installed"
}

# Stow configs
stow_configs() {
    log "Stowing configs..."
    
    cd "$DOTFILES_DIR"
    mkdir -p ~/.config
    
    for dir in */; do
        local pkg="${dir%/}"
        [[ "$pkg" == ".git" ]] && continue
        [[ "$pkg" == ".github" ]] && continue
        [[ "$pkg" == "packages" ]] && continue
        [[ "$pkg" == "bin" ]] && continue
        [[ ! -d "$pkg/.config" ]] && [[ ! -f "$pkg/.zshrc" ]] && continue
        
        stow --dotfiles -t "$HOME" "$pkg" 2>/dev/null && echo "  $pkg" || warn "$pkg conflict (skipped)"
    done
    
    ok "Configs stowed"
}

# Configure git from .env
config_git() {
    if [[ -n "${GIT_USER_NAME:-}" ]]; then
        git config --global user.name "$GIT_USER_NAME"
        log "Git user.name set"
    fi
    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
        git config --global user.email "$GIT_USER_EMAIL"
        log "Git user.email set"
    fi
}

# Post install
post() {
    config_git
    [[ "$SHELL" != *"zsh"* ]] && chsh -s "$(which zsh)" 2>/dev/null || true
    systemctl --user enable ssh-agent.service 2>/dev/null || true
}

# Main
main() {
    echo "Dotfiles Installer"
    echo "=================="
    
    check
    
    case "${1:-}" in
        --packages)
            install_packages
            ;;
        --stow)
            stow_configs
            post
            ;;
        *)
            log "Updating system..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --needed --noconfirm archlinux-keyring
            
            install_yay
            install_packages
            stow_configs
            post
            
            echo ""
            ok "Done! Reboot: sudo reboot"
            ;;
    esac
}

main "$@"
