#!/bin/bash
set -e

# =============================================================================
# Dotfiles Installation Script for Arch Linux
# =============================================================================
# One script to rule them all - works on fresh installs and updates
# 
# Usage:
#   ./install.sh              Full install (recommended for new setups)
#   ./install.sh --packages   Only install packages
#   ./install.sh --stow       Only stow configs
#   ./install.sh --help       Show help message
# 
# What this script does:
#   1. Checks system requirements (internet, sudo, arch)
#   2. Installs yay (AUR helper)
#   3. Installs ALL packages from packages/*.txt files
#   4. Stows config files using GNU Stow
#   5. Sets up git, shell, and services
# 
# Features:
#   - Shows detailed progress and error messages
#   - Reports which packages failed to install
#   - No silent failures (unlike the old version!)
#   - Works on both fresh installs and existing systems
#   - Auto-tracking: Packages are automatically added to package lists
# 
# Auto-Tracking Setup:
#   After installation, run this to enable automatic package tracking:
#   sudo cp pacman-hook-autotrack.hook /usr/share/libalpm/hooks/20-dotfiles-autotrack.hook
# 
#   Now every pacman/yay install will automatically update your package lists!
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env if exists
[[ -f "$DOTFILES_DIR/.env" ]] && source "$DOTFILES_DIR/.env"

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
MAGENTA='\\033[0;35m'
CYAN='\\033[0;36m'
NC='\\033[0m'

log() { echo -e "${BLUE}[install]${NC} $1"; }
ok() { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; }
info() { echo -e "${CYAN}[info]${NC} $1"; }

# Checks
check() {
    local errors=0
    
    info "Running pre-install checks..."
    
    [[ $EUID -eq 0 ]] && { error "Don't run as root"; errors=$((errors+1)); }
    [[ ! -f /etc/arch-release ]] && { error "Arch Linux only"; errors=$((errors+1)); }
    [[ -z "$HOME" ]] && { error "HOME not set"; errors=$((errors+1)); }
    
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        error "No internet connection"
        errors=$((errors+1))
    fi
    
    if ! sudo -v &>/dev/null; then
        error "Sudo access required"
        errors=$((errors+1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        error "$errors error(s) found. Please fix them and try again."
        exit 1
    fi
    
    ok "All checks passed"
    echo ""
}

# Install yay
install_yay() {
    if command -v yay &>/dev/null; then
        ok "yay already installed"
        return
    fi
    
    log "Installing yay AUR helper..."
    local tmp=$(mktemp -d)
    
    if git clone https://aur.archlinux.org/yay.git "$tmp/yay"; then
        cd "$tmp/yay"
        if makepkg -si --noconfirm; then
            ok "yay installed successfully"
        else
            error "Failed to build yay"
            return 1
        fi
    else
        error "Failed to clone yay"
        return 1
    fi
    
    rm -rf "$tmp"
}

# Install packages
install_packages() {
    log "Installing packages..."
    
    local failed_pacman=()
    local failed_aur=()
    local total_installed=0
    
    # Essentials (install first to ensure they exist)
    local essentials="zsh git curl wget stow base-devel"
    log "Installing essentials: $essentials"
    if sudo pacman -S --needed --noconfirm $essentials; then
        ok "Essentials installed"
    else
        warn "Some essentials failed to install"
        failed_pacman+=("essentials")
    fi
    
    # From lists
    log "Installing packages from package lists..."
    for file in packages/*.txt; do
        [[ "$file" == *"aur.txt" ]] && continue
        
        log "  Processing: $file"
        local pkgs=$(grep -v '^#' "$file" | grep -v '^$' | tr '\n' ' ')
        
        if [[ -n "$pkgs" ]]; then
            if sudo pacman -S --needed --noconfirm $pkgs 2>&1 | tee /tmp/pacman-install.log; then
                local count=$(grep -o 'installing' /tmp/pacman-install.log | wc -l)
                total_installed=$((total_installed + count))
                log "    ✓ $file ($count packages)"
            else
                warn "    ✗ $file - some packages failed"
                failed_pacman+=("$file")
            fi
        fi
    done
    
    # AUR
    if [[ -f "packages/aur.txt" ]] && command -v yay &>/dev/null; then
        log "Installing AUR packages..."
        local aur_pkgs=$(grep -v '^#' packages/aur.txt | grep -v '^$' | tr '\n' ' ')
        
        if [[ -n "$aur_pkgs" ]]; then
            if yay -S --needed --noconfirm $aur_pkgs 2>&1 | tee /tmp/yay-install.log; then
                local aur_count=$(grep -o 'installing\|downloading' /tmp/yay-install.log | wc -l)
                total_installed=$((total_installed + aur_count))
                ok "AUR packages installed"
            else
                warn "Some AUR packages failed"
                failed_aur+=("aur packages")
            fi
        fi
    fi
    
    # Verify critical packages installed
    log "Verifying critical packages..."
    local missing=()
    local critical=(zsh git curl wget stow hyprpaper hyprland waybar nvim tmux fzf eza bat starship zoxide)
    
    for pkg in "${critical[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing critical packages: ${missing[*]}"
        log "Install them with: sudo pacman -S ${missing[*]}"
    else
        ok "All critical packages installed"
    fi
    
    # Summary
    echo ""
    echo "========================================="
    ok "Installation Summary"
    echo "========================================="
    echo "Total packages installed: $total_installed"
    
    if [[ ${#failed_pacman[@]} -gt 0 ]]; then
        warn "Failed package files: ${failed_pacman[*]}"
    fi
    
    if [[ ${#failed_aur[@]} -gt 0 ]]; then
        warn "Failed AUR packages: ${failed_aur[*]}"
    fi
    
    if [[ ${#failed_pacman[@]} -eq 0 && ${#failed_aur[@]} -eq 0 ]]; then
        ok "All packages installed successfully!"
    else
        warn "Check /tmp/pacman-install.log or /tmp/yay-install.log for details"
    fi
    echo "========================================="
}

# Stow configs
stow_configs() {
    log "Stowing configs..."
    
    cd "$DOTFILES_DIR"
    mkdir -p ~/.config
    
    local stowed=()
    local skipped=()
    
    for dir in */; do
        local pkg="${dir%/}"
        [[ "$pkg" == ".git" ]] && continue
        [[ "$pkg" == ".github" ]] && continue
        [[ "$pkg" == "packages" ]] && continue
        [[ "$pkg" == "bin" ]] && continue
        [[ "$pkg" == "scripts" ]] && continue
        [[ ! -d "$pkg/.config" ]] && [[ ! -f "$pkg/.zshrc" ]] && [[ ! -f "$pkg/.tmux.conf" ]] && [[ ! -f "$pkg/.gitconfig" ]] && continue
        
        info "  Stowing: $pkg"
        if stow --dotfiles -t "$HOME" "$pkg"; then
            stowed+=("$pkg")
            log "    ✓ $pkg"
        else
            warn "    ✗ $pkg conflict or error (skipped)"
            skipped+=("$pkg")
        fi
    done
    
    echo ""
    ok "Stowed ${#stowed[@]} packages"
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "Skipped ${#skipped[@]} packages: ${skipped[*]}"
    fi
}

# Configure git from .env
config_git() {
    if [[ ! -f "$DOTFILES_DIR/.env" ]]; then
        info "No .env file found, skipping git config"
        return
    fi
    
    if [[ -n "${GIT_USER_NAME:-}" ]]; then
        git config --global user.name "$GIT_USER_NAME"
        log "Git user.name set to: $GIT_USER_NAME"
    fi
    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
        git config --global user.email "$GIT_USER_EMAIL"
        log "Git user.email set to: $GIT_USER_EMAIL"
    fi
}

# Post install
post() {
    log "Post-install setup..."
    
    # Configure git from .env
    config_git
    
    # Set zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Setting zsh as default shell..."
        if chsh -s "$(which zsh)"; then
            ok "zsh is now default shell"
        else
            warn "Could not set zsh as default shell (run: chsh -s $(which zsh))"
        fi
    else
        ok "zsh is already default shell"
    fi
    
    # Enable ssh-agent
    info "Enabling ssh-agent service..."
    if systemctl --user enable ssh-agent.service; then
        ok "ssh-agent enabled"
    else
        warn "Could not enable ssh-agent (may not be critical)"
    fi
    
    # Setup automatic package tracking
    if [[ -x "$DOTFILES_DIR/scripts/setup-autotrack.sh" ]]; then
        info "Setting up automatic package tracking..."
        if bash "$DOTFILES_DIR/scripts/setup-autotrack.sh"; then
            ok "Automatic package tracking enabled"
        else
            warn "Auto-tracking setup failed (run manually: ./scripts/setup-autotrack.sh)"
        fi
    else
        warn "Auto-tracking script not found (skipping)"
    fi
}

# Main
main() {
    # Handle help first (before checks)
    case "${1:-}" in
        --help|-h)
            echo ""
            echo "╔══════════════════════════════════════════════════════════╗"
            echo "║           Dotfiles Installer for Arch Linux               ║"
            echo "╚══════════════════════════════════════════════════════════╝"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (no args)    Full install (update + packages + stow)"
            echo "  --packages   Only install packages"
            echo "  --stow       Only stow configs"
            echo "  --help,-h    Show this help message"
            echo ""
            exit 0
            ;;
    esac
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           Dotfiles Installer for Arch Linux               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
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
            log "Step 1/4: Updating system packages..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --needed --noconfirm archlinux-keyring
            
            log "Step 2/4: Installing AUR helper (yay)..."
            install_yay
            
            log "Step 3/4: Installing all packages..."
            install_packages
            
            log "Step 4/4: Stowing configuration files..."
            stow_configs
            
            post
            
            echo ""
            ok "Installation complete!"
            echo "────────────────────────────────────────────────────────"
            echo ""
            info "Next steps:"
            echo "  1. Reboot your system: sudo reboot"
            echo "  2. Or restart your shell: exec zsh"
            echo "  3. Customize your config: nvim ~/.config/zsh/.zshrc"
            echo ""
            warn "Some applications may need manual setup:"
            echo "  - SDKMAN: curl -s \"https://get.sdkman.io\" | bash"
            echo "  - NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
            echo ""
            ;;
    esac
}

main "$@"