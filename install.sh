#!/bin/bash

# =============================================================================
# Dotfiles Installation Script for Arch Linux
# =============================================================================
# One script to rule them all - works on fresh installs and updates
# =============================================================================

set -e

# Colors (check if terminal supports them)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root (DON'T!)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root!"
        echo "Run as your normal user with sudo access."
        exit 1
    fi
}

# Check Arch
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This script is for Arch Linux only!"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check HOME is set
    if [[ -z "$HOME" ]] || [[ ! -d "$HOME" ]]; then
        log_error "HOME directory not set or doesn't exist!"
        exit 1
    fi
    
    # Check internet
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        log_error "No internet connection! Connect to WiFi first:"
        echo "  nmcli device wifi list"
        echo "  nmcli device wifi connect <SSID> --ask"
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} Internet connection OK"
    
    # Check disk space (need at least 5GB)
    local free_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $free_space -lt 5242880 ]]; then  # 5GB in KB
        log_error "Not enough disk space! Need at least 5GB free."
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} Disk space OK"
    
    # Check sudo access
    echo -n "  Checking sudo access... "
    if sudo -v; then
        echo -e "${GREEN}OK${NC}"
    else
        log_error "Sudo access denied!"
        exit 1
    fi
    
    log_success "Prerequisites OK"
}

# Initialize pacman keyring (needed on fresh installs)
init_keyring() {
    log_info "Initializing pacman keyring..."
    sudo pacman-key --init 2>/dev/null || true
    sudo pacman-key --populate archlinux 2>/dev/null || true
}

# Update system first
update_system() {
    log_info "Updating system..."
    log_warn "This may take a few minutes..."
    
    # Full system update
    sudo pacman -Syu --noconfirm
    
    # Update keyring to prevent signature errors
    log_info "Updating archlinux-keyring..."
    sudo pacman -S --needed --noconfirm archlinux-keyring
    
    log_success "System updated"
}

# Install yay
install_yay() {
    if command -v yay &> /dev/null; then
        return
    fi
    log_info "Installing yay..."
    
    # Create temp dir in HOME in case /tmp is noexec
    local temp_dir="$HOME/.tmp-yay-build-$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm || {
        log_error "Failed to build yay!"
        cd "$DOTFILES_DIR"
        rm -rf "$temp_dir"
        exit 1
    }
    
    cd "$DOTFILES_DIR"
    rm -rf "$temp_dir"
    log_success "yay installed"
}

# Install essential packages first - CRITICAL, must succeed
install_essential() {
    log_info "Installing essential packages first..."
    
    local essentials=(
        "zsh"
        "git"
        "curl"
        "wget"
        "stow"
        "base-devel"
        "libxml2"
        "openconnect"
    )
    
    # Install one by one to identify failures
    local failed=()
    for pkg in "${essentials[@]}"; do
        echo -n "  Installing $pkg... "
        if sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            failed+=("$pkg")
        fi
    done
    
    # Check if any critical packages failed
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install essential packages: ${failed[*]}"
        log_info "Please install them manually and try again:"
        echo "  sudo pacman -S ${failed[*]}"
        exit 1
    fi
    
    # Verify zsh is actually installed
    if ! command -v zsh &>/dev/null; then
        log_error "Zsh installation failed! Zsh is required."
        exit 1
    fi
    
    # Create ~/.config if it doesn't exist
    mkdir -p ~/.config
    
    log_success "Essential packages installed"
}

# Install packages in batches
install_packages() {
    log_info "Installing all packages..."
    log_warn "This will take 10-15 minutes..."
    
    # Collect all packages
    local all_pkgs=()
    for file in packages/*.txt; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" == *"aur.txt" ]] && continue
        
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            all_pkgs+=("$line")
        done < "$file"
    done
    
    # Install in batches of 50
    local total=${#all_pkgs[@]}
    local batch_size=50
    local installed=0
    
    log_info "Installing $total packages in batches..."
    
    for ((i=0; i<total; i+=batch_size)); do
        local batch=("${all_pkgs[@]:i:batch_size}")
        local batch_num=$((i/batch_size + 1))
        local total_batches=$(((total + batch_size - 1) / batch_size))
        
        echo "  Batch $batch_num/$total_batches (${#batch[@]} packages)..."
        if sudo pacman -S --needed --noconfirm --overwrite '*' "${batch[@]}" 2>&1 | tail -3; then
            installed=$((installed + ${#batch[@]}))
        else
            log_warn "Batch $batch_num may have had some failures"
        fi
    done
    
    echo -e "  ${GREEN}✓${NC} Installed $installed packages"
    
    # Install AUR packages
    if [[ -f "packages/aur.txt" ]]; then
        log_info "Installing AUR packages..."
        local aur_pkgs=()
        
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            aur_pkgs+=("$line")
        done < "packages/aur.txt"
        
        if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
            echo "  Installing ${#aur_pkgs[@]} AUR packages..."
            if yay -S --needed --noconfirm "${aur_pkgs[@]}" 2>&1 | tail -5; then
                echo -e "  ${GREEN}✓${NC} AUR packages installed"
            else
                log_warn "Some AUR packages may have failed (this is normal)"
            fi
        fi
    fi
    
    log_success "Package installation complete"
}

# Install Cisco AnyConnect for NTNU VPN
install_ntnu_vpn() {
    log_info "Checking for NTNU Cisco AnyConnect VPN..."
    
    if command -v vpn &> /dev/null || [[ -d "/opt/cisco/anyconnect" ]]; then
        log_success "Cisco AnyConnect appears to be installed"
        return
    fi
    
    log_info "To install Cisco AnyConnect for NTNU:"
    echo "  1. Download from: https://i.ntnu.no/wiki/-/wiki/English/Install+VPN"
    echo "  2. Or install via AUR: yay -S cisco-anyconnect"
    echo ""
    echo -n "Install via AUR now? (y/N): "
    read -t 10 -r response || response="n"
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if command -v yay &> /dev/null; then
            yay -S --needed cisco-anyconnect || log_warn "Cisco AnyConnect installation failed"
        else
            log_warn "yay not available"
        fi
    else
        log_info "Skipping (install later with: yay -S cisco-anyconnect)"
    fi
}

# Stow packages
stow_packages() {
    log_info "Stowing dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # Ensure ~/.config exists
    mkdir -p ~/.config
    
    # Backup existing configs first
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        log_warn "Backing up existing .zshrc to .zshrc.backup"
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
    fi
    
    # Find all packages
    local packages=()
    for dir in */; do
        [[ "$dir" == ".git/" ]] && continue
        [[ "$dir" == "scripts/" ]] && continue
        [[ "$dir" == "packages/" ]] && continue
        [[ "$dir" == ".github/" ]] && continue
        [[ "$dir" == "bin/" ]] && continue
        
        if [[ -d "$dir/.config" ]] || [[ -f "$dir/.zshrc" ]] || [[ -f "$dir/.tmux.conf" ]] || [[ -f "$dir/.gitconfig" ]]; then
            packages+=("${dir%/}")
        fi
    done
    
    log_info "Found ${#packages[@]} packages to stow"
    
    # Stow each with better error handling
    local failed_pkgs=()
    for pkg in "${packages[@]}"; do
        echo -n "  $pkg... "
        
        # Try normal stow first, show error if it fails
        if stow --dotfiles -t "$HOME" "$pkg" 2>&1; then
            echo -e "${GREEN}OK${NC}"
        else
            echo ""
            log_warn "Stow conflict for $pkg, adopting existing files..."
            if stow --dotfiles --adopt -t "$HOME" "$pkg" 2>&1; then
                echo -e "  ${GREEN}✓${NC} $pkg stowed (adopted)"
            else
                log_error "Failed to stow $pkg"
                failed_pkgs+=("$pkg")
            fi
        fi
    done
    
    if [[ ${#failed_pkgs[@]} -eq 0 ]]; then
        log_success "Dotfiles stowed"
    else
        log_warn "Some packages failed to stow: ${failed_pkgs[*]}"
        log_info "You can try stowing them manually:"
        for pkg in "${failed_pkgs[@]}"; do
            echo "  stow --dotfiles -t ~ $pkg"
        done
    fi
}

# Post install
post_install() {
    log_info "Post-installation setup..."
    
    # Install oh-my-zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-my-zsh..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_success "Oh-my-zsh installed"
        else
            log_warn "Oh-my-zsh installation failed"
        fi
    fi
    
    # Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_info "Installing Tmux Plugin Manager..."
        if git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null; then
            log_success "TPM installed"
        else
            log_warn "TPM installation failed"
        fi
    fi
    
    # Change shell to zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Changing default shell to zsh..."
        if sudo chsh -s /bin/zsh "$USER"; then
            log_success "Shell changed to zsh (logout/login to apply)"
        else
            log_warn "Could not change shell automatically"
            echo "  Run manually: chsh -s /bin/zsh"
        fi
    fi
    
    # Check video group
    if ! id -nG "$USER" | grep -qw "video"; then
        log_warn "Adding user to 'video' group (needed for Hyprland)"
        sudo usermod -aG video "$USER"
        log_success "Added user to video group"
    fi
    
    # Enable services
    log_info "Enabling system services..."
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable bluetooth 2>/dev/null || true
    sudo systemctl enable sddm 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
    log_success "Services enabled"
    
    # Directories
    mkdir -p ~/Desktop/{projects,orbit,moenmarin}
    mkdir -p ~/Downloads ~/Documents ~/Pictures ~/Videos
    
    # Create .zshhist
    touch ~/.zshhist
    
    log_success "Post-install complete"
}

# Verify installation
verify() {
    log_info "Verifying installation..."
    
    local all_good=true
    local missing_pkgs=()
    
    # Check key files
    [[ -L "$HOME/.zshrc" ]] && echo -e "  ${GREEN}✓${NC} .zshrc" || { echo -e "  ${RED}✗${NC} .zshrc"; all_good=false; }
    [[ -L "$HOME/.tmux.conf" ]] && echo -e "  ${GREEN}✓${NC} .tmux.conf" || { echo -e "  ${RED}✗${NC} .tmux.conf"; all_good=false; }
    [[ -L "$HOME/.gitconfig" ]] && echo -e "  ${GREEN}✓${NC} .gitconfig" || { echo -e "  ${RED}✗${NC} .gitconfig"; all_good=false; }
    [[ -L "$HOME/.config/nvim" ]] && echo -e "  ${GREEN}✓${NC} nvim" || { echo -e "  ${RED}✗${NC} nvim"; all_good=false; }
    [[ -L "$HOME/.config/hypr" ]] && echo -e "  ${GREEN}✓${NC} hypr" || { echo -e "  ${RED}✗${NC} hypr"; all_good=false; }
    
    # Check critical packages
    echo ""
    log_info "Checking critical packages..."
    
    for pkg in zsh git curl wget stow eza fzf zoxide bat; do
        if command -v "$pkg" &> /dev/null || pacman -Q "$pkg" &>/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg MISSING!"
            missing_pkgs+=("$pkg")
            all_good=false
        fi
    done
    
    if $all_good; then
        echo ""
        log_success "All checks passed!"
        return 0
    else
        echo ""
        log_error "Some items missing!"
        if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            log_info "Install missing packages with:"
            echo "  sudo pacman -S ${missing_pkgs[*]}"
        fi
        return 1
    fi
}

# Main
main() {
    echo -e "${BLUE}"
    echo "  Dotfiles Installer"
    echo "======================"
    echo -e "${NC}"
    
    check_not_root
    check_arch
    check_prerequisites
    init_keyring
    update_system
    install_yay
    install_essential
    install_packages
    install_ntnu_vpn
    stow_packages
    post_install
    verify
    
    echo ""
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Log out and log back in (for zsh shell)"
    echo "  2. Reboot to start Hyprland: sudo reboot"
    echo "  3. In tmux: press Ctrl+Space + I for plugins"
    echo "  4. In nvim: wait for plugins to auto-install"
    echo ""
}

main "$@"
