#!/bin/bash
# Unified Package Tracking Script - Works as root via pacman hook
# Handles multi-user scenarios, SUDO_USER detection, git integration.

# ============================================
# CONFIGURATION & PATH DETECTION
# ============================================

# Handle SUDO_USER (pacman runs as root)
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Auto-detect dotfiles location (multi-OS compatible)
DOTFILES_LOCATIONS=(
    "$HOME/Desktop/dotfiles"
    "$HOME/dotfiles"
    "$HOME/.dotfiles"
    "$HOME/Documents/dotfiles"
)

DOTFILES_DIR=""
for location in "${DOTFILES_LOCATIONS[@]}"; do
    if [[ -d "$location" ]]; then
        DOTFILES_DIR="$location"
        break
    fi
done

# Fallback: use script location to find dotfiles
if [[ -z "$DOTFILES_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
fi

PACKAGES_DIR="$DOTFILES_DIR/packages"
AUTO_PACKAGES="$PACKAGES_DIR/auto-tracked.txt"

# ============================================
# INITIALIZATION
# ============================================

# Create auto-tracked file if not exists
[[ ! -f "$AUTO_PACKAGES" ]] && touch "$AUTO_PACKAGES"

# ============================================
# PACKAGE DETECTION
# ============================================

# Get packages from pacman hook or recent installs
if [[ -n "$H_PKGNAME" ]]; then
    PACKAGES="$H_PKGNAME"
else
    # Fallback: get recently installed packages (last 5 minutes)
    PACKAGES=$(pacman -Qqe 2>/dev/null | while read pkg; do
        if pacman -Qi "$pkg" 2>/dev/null | grep -A 5 "Install Date" | grep -q "$(date '+%Y-%m-%d %H')" 2>/dev/null; then
            echo "$pkg"
        fi
    done)
fi

# ============================================
# PACKAGE CATEGORIZATION & TRACKING
# ============================================

track_package() {
    local pkg="$1"
    [[ -z "$pkg" ]] && return
    
    # Skip if already tracked
    grep -q "^${pkg}$" "$PACKAGES_DIR"/*.txt 2>/dev/null && return
    
    # Categorize and append
    if yay -Qi "$pkg" &>/dev/null 2>&1; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/aur.txt" || echo "$pkg" >> "$PACKAGES_DIR/aur.txt"
        echo "[+] $pkg -> aur.txt"
    elif echo "$pkg" | grep -E "(docker|git|node|python|go|java|rust|cmake|clang|build|devel)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/development.txt" || echo "$pkg" >> "$PACKAGES_DIR/development.txt"
        echo "[+] $pkg -> development.txt"
    elif echo "$pkg" | grep -E "(hypr|waybar|wofi|sway|pk|xdg|kde|gnome|plasma)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/desktop.txt" || echo "$pkg" >> "$PACKAGES_DIR/desktop.txt"
        echo "[+] $pkg -> desktop.txt"
    elif echo "$pkg" | grep -E "(vim|nvim|tmux|fzf|eza|bat|starship|zsh|shell|term)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/terminal.txt" || echo "$pkg" >> "$PACKAGES_DIR/terminal.txt"
        echo "[+] $pkg -> terminal.txt"
    elif echo "$pkg" | grep -E "(firefox|brave|chrom|slack|spotify|obsidian|libreoffice|code|ide)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/applications.txt" || echo "$pkg" >> "$PACKAGES_DIR/applications.txt"
        echo "[+] $pkg -> applications.txt"
    else
        grep -q "^${pkg}$" "$PACKAGES_DIR/core.txt" || echo "$pkg" >> "$PACKAGES_DIR/core.txt"
        echo "[+] $pkg -> core.txt"
    fi
}

# Process each package
echo "$PACKAGES" | while read -r pkg; do
    track_package "$pkg"
done

# ============================================
# CLEANUP & VALIDATION
# ============================================

# Sort all package files (remove duplicates)
for file in "$PACKAGES_DIR"/*.txt; do
    [[ -f "$file" ]] || continue
    temp_file=$(mktemp)
    sort -u "$file" > "$temp_file"
    mv "$temp_file" "$file"
done

# ============================================
# GIT INTEGRATION
# ============================================

if [[ -d "$DOTFILES_DIR/.git" ]] && command -v git &>/dev/null; then
    cd "$DOTFILES_DIR" || exit 0
    
    # Add package changes
    git add packages/*.txt >/dev/null 2>&1
    
    # Check if there are changes to commit
    if git diff --cached --quiet packages/; then
        # No changes, skip
        exit 0
    fi
    
    # Build commit message
    pkg_list=$(echo "$PACKAGES" | tr '\n' ' ' | sed 's/ $//')
    
    # Get hostname (works when running as root)
    if [[ -f /etc/hostname ]]; then
        hostname=$(cat /etc/hostname)
    elif [[ -f /proc/sys/kernel/hostname ]]; then
        hostname=$(cat /proc/sys/kernel/hostname)
    else
        hostname="unknown"
    fi
    
    # Detect machine type
    if ls /sys/class/power_supply/ | grep -q BAT 2>/dev/null; then
        machine_type="laptop"
    else
        machine_type="desktop"
    fi
    
    commit_msg="[AUTO] [$hostname:$machine_type] Tracked packages: $pkg_list"
    
    # Commit changes
    if git commit -m "$commit_msg" >/dev/null 2>&1; then
        echo "[git] Auto-committed: $pkg_list"
        
        # Auto-push using gh CLI
        if command -v gh &>/dev/null && gh auth status &>/dev/null; then
            if git push origin master >/dev/null 2>&1; then
                echo "[git] Auto-pushed to GitHub via gh"
            else
                echo "[git] Push failed - check SSH keys"
            fi
        else
            echo "[git] Push skipped - gh CLI not authenticated"
        fi
    else
        echo "[git] Commit failed"
        exit 1
    fi
fi

exit 0
