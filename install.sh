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
export DOTFILES_DIR

# Load shared library (logger, is_stow_package, list_stow_packages)
source "$DOTFILES_DIR/scripts/config.sh"

# Load .env if exists
[[ -f "$DOTFILES_DIR/.env" ]] && { set -a; source "$DOTFILES_DIR/.env"; set +a; }

# Backward-compat aliases (older code in this script uses `error`)
error() { err "$@"; }

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
    
    local failed_pacman_pkgs=()
    local failed_aur_pkgs=()
    local total_installed=0
    
    # Essentials (install first to ensure they exist)
    local essentials="zsh git curl wget stow base-devel"
    log "Installing essentials: $essentials"
    if sudo pacman -S --needed --noconfirm $essentials; then
        ok "Essentials installed"
    else
        warn "Some essentials failed to install"
        failed_pacman_pkgs+=("essentials")
    fi
    
    # Official repos
    if [[ -d "packages" ]]; then
        log "Installing packages from package lists..."
        for file in packages/*.txt; do
            [[ "$file" == *"aur.txt" ]] && continue
        
        log "  Processing: $file"
        local pkgs=$(grep -v '^#' "$file" | grep -v '^$' | tr '\n' ' ')
        
        if [[ -n "$pkgs" ]]; then
            # Try to install and capture errors
            if sudo pacman -S --needed --noconfirm $pkgs 2>&1 | tee /tmp/pacman-install.log; then
                local count=$(grep -o 'installing' /tmp/pacman-install.log | wc -l)
                total_installed=$((total_installed + count))
                log "    ✓ $file ($count packages)"
            else
                warn "    ⚠ $file - some packages may have issues"
                # Find which packages specifically failed
                for pkg in $pkgs; do
                    if ! pacman -Q "$pkg" &>/dev/null; then
                        failed_pacman_pkgs+=("$pkg")
                    fi
                done
            fi
        fi
    done
    else
        warn "packages directory not found, skipping package installation"
    fi
    
    # AUR
    if [[ -d "packages" && -f "packages/aur.txt" ]] && command -v yay &>/dev/null; then
        log "Installing AUR packages..."
        local aur_pkgs=$(grep -v '^#' packages/aur.txt | grep -v '^$' | tr '\n' ' ')
        
        if [[ -n "$aur_pkgs" ]]; then
            if yay -S --needed --noconfirm $aur_pkgs 2>&1 | tee /tmp/yay-install.log; then
                local aur_count=$(grep -c 'installing' /tmp/yay-install.log 2>/dev/null || echo "0")
                total_installed=$((total_installed + aur_count))
                ok "AUR packages installed"
            else
                warn "Some AUR packages failed (may not be available)"
                # Find which AUR packages specifically failed
                for pkg in $aur_pkgs; do
                    if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
                        failed_aur_pkgs+=("$pkg")
                    fi
                done
            fi
        else
            info "No AUR packages to install"
        fi
    else
        info "No aur.txt found or yay not available, skipping AUR packages"
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
    
    if [[ ${#failed_pacman_pkgs[@]} -gt 0 ]]; then
        warn "Failed packages (official repos):"
        for pkg in "${failed_pacman_pkgs[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    if [[ ${#failed_aur_pkgs[@]} -gt 0 ]]; then
        warn "Failed packages (AUR - may not be critical):"
        for pkg in "${failed_aur_pkgs[@]}"; do
            echo "  - $pkg"
        done
        warn "These may be unavailable or require manual install"
    fi
    
    if [[ ${#failed_pacman_pkgs[@]} -eq 0 && ${#failed_aur_pkgs[@]} -eq 0 ]]; then
        ok "All packages installed successfully!"
    else
        warn "Some packages failed (non-critical). System is usable."
    fi
    echo "========================================="
}

# Install packages from a single profile (packages/profiles/<name>.txt).
# Auto-detects AUR vs official repos so each profile can mix both freely.
install_profile() {
    local profile="$1"
    local profile_file="$DOTFILES_DIR/packages/profiles/${profile}.txt"

    if [[ ! -f "$profile_file" ]]; then
        err "Profile not found: $profile_file"
        info "Available profiles:"
        for f in "$DOTFILES_DIR/packages/profiles/"*.txt; do
            [[ -f "$f" ]] && echo "  - $(basename "${f%.txt}")"
        done
        exit 1
    fi

    log "Installing profile: $profile"
    local pkgs=()
    while IFS= read -r line; do
        line="${line%%#*}"      # strip comments
        line="${line//[[:space:]]/}"
        [[ -z "$line" ]] && continue
        pkgs+=("$line")
    done < "$profile_file"

    [[ ${#pkgs[@]} -eq 0 ]] && { warn "Profile is empty"; return; }

    local official=() aur=()
    for pkg in "${pkgs[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            official+=("$pkg")
        else
            aur+=("$pkg")
        fi
    done

    if [[ ${#official[@]} -gt 0 ]]; then
        log "Pacman: ${#official[@]} package(s)"
        sudo pacman -S --needed --noconfirm "${official[@]}" || warn "Some pacman packages failed"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        if command -v yay &>/dev/null; then
            log "AUR: ${#aur[@]} package(s)"
            yay -S --needed --noconfirm "${aur[@]}" || warn "Some AUR packages failed"
        else
            warn "yay not installed - skipping ${#aur[@]} AUR package(s): ${aur[*]}"
        fi
    fi

    ok "Profile '$profile' applied"
}

# Stow configs
stow_configs() {
    log "Stowing configs..."
    
    cd "$DOTFILES_DIR"
    mkdir -p ~/.config
    
    local stowed=()
    local skipped=()
    
    local pkg
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        info "  Stowing: $pkg"
        if stow --dotfiles -t "$HOME" "$pkg"; then
            stowed+=("$pkg")
            log "    ok $pkg"
        else
            warn "    failed $pkg (conflict or error)"
            skipped+=("$pkg")
        fi
    done < <(list_stow_packages)
    
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
    if systemctl --user enable ssh-agent.socket &>/dev/null; then
        ok "ssh-agent enabled"
    else
        warn "Could not enable ssh-agent (may not be critical)"
    fi
    
    # Setup automatic package tracking (optional - requires sudo)
    if [[ -x "$DOTFILES_DIR/install-hook.sh" ]]; then
        info "Setting up automatic package tracking..."
        if bash "$DOTFILES_DIR/install-hook.sh"; then
            ok "Automatic package tracking enabled"
        else
            warn "Auto-tracking setup failed (run manually: ./install-hook.sh)"
        fi
    else
        warn "install-hook.sh not found (skipping auto-tracking)"
    fi
    
    # Reload configurations if running in session
    log "Applying configuration changes..."
    
    # Reload Hyprland components if running
    if pgrep -x "Hyprland" &>/dev/null; then
        if command -v hyprctl &>/dev/null; then
            info "Reloading Hyprland..."
            hyprctl reload &>/dev/null && ok "Hyprland reloaded" || warn "Could not reload Hyprland"
        fi
        
        if command -v hyprpaper &>/dev/null; then
            info "Reloading hyprpaper..."
            if pgrep -x "hyprpaper" &>/dev/null; then
                hyprpaper reload &>/dev/null && ok "hyprpaper reloaded" || warn "Could not reload hyprpaper"
            else
                # Start hyprpaper if not running but installed
                if command -v hyprpaper &>/dev/null; then
                    info "Starting hyprpaper..."
                    hyprpaper &>/dev/null &
                else
                    warn "hyprpaper not found, skipping"
                fi
            fi
        fi
        
        # Reload waybar if running
        if pgrep -x "waybar" &>/dev/null; then
            info "Reloading waybar..."
            killall -SIGUSR2 waybar &>/dev/null && ok "waybar reloaded" || warn "Could not reload waybar"
        fi
    fi
    
    # Reload kitty if running
    if pgrep -x "kitty" &>/dev/null; then
        info "Reloading kitty..."
        killall -SIGUSR1 kitty &>/dev/null && ok "kitty reloaded" || warn "Could not reload kitty"
    fi
    
    # Source zsh config if running in zsh
    if [[ -n $ZSH_VERSION ]]; then
        info "Sourcing zsh configuration..."
        source "$HOME/.zshrc" &>/dev/null && ok "zsh configuration sourced" || warn "Could not source zsh configuration"
    fi
    
    # Reload systemd user units
    info "Reloading systemd user daemon..."
    systemctl --user daemon-reload &>/dev/null && ok "systemd user daemon reloaded" || warn "Could not reload systemd user daemon"
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
            echo "  (no args)            Full install (update + packages + stow)"
            echo "  --packages           Install all packages (packages.txt + aur.txt)"
            echo "  --profile <name>     Install just one profile (packages/profiles/<name>.txt)"
            echo "  --stow               Only stow configs"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Available profiles:"
            for f in "$DOTFILES_DIR/packages/profiles/"*.txt; do
                [[ -f "$f" ]] && echo "  - $(basename "${f%.txt}")"
            done
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
        --profile)
            [[ -z "${2:-}" ]] && { err "--profile requires a name (see ./install.sh --help)"; exit 1; }
            install_profile "$2"
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
            info "Changes applied! Most services reloaded automatically."
            echo ""
            info "Optional next steps:"
            echo "  1. Customize your config: nvim ~/.config/zsh/.zshrc"
            echo "  2. Reboot if you want to ensure all changes take effect: sudo reboot"
            echo "  3. Restart your shell if needed: exec zsh"
            echo ""
            warn "Some applications may need manual setup:"
            echo "  - SDKMAN: curl -s \"https://get.sdkman.io\" | bash"
            echo "  - NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
            echo ""
            ;;
    esac
}

main "$@"