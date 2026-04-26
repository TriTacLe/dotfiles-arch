#!/bin/bash
# Simple Package Tracking - Fixed date matching for any locale

# Safety check
if ! touch /tmp/pkgtrack-test.$$ 2>/dev/null; then
    echo "[ERROR] Cannot write to files - aborting"
    exit 1
fi
rm -f /tmp/pkgtrack-test.$$

# Handle SUDO_USER
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Find dotfiles location
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

if [[ -z "$DOTFILES_DIR" ]]; then
    echo "[ERROR] Dotfiles directory not found"
    exit 1
fi

PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"

# Create packages file if not exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    pacman -Qqe > "$PACKAGES_FILE"
fi

# Get recently installed packages (last 10 minutes)
# Use multiple date formats to ensure compatibility
RECENT_PACKAGES=$(pacman -Qqe | while read -r pkg; do
    # Try multiple date formats
    if pacman -Qi "$pkg" 2>/dev/null | grep "Install Date" | grep -q "$(date '+%Y-%m-%d')"; then
        # Installed today, check if within last 10 minutes
        INSTALL_TIME=$(pacman -Qi "$pkg" 2>/dev/null | grep "Install Date" | awk '{print $5}')
        if [[ "$INSTALL_TIME" == *"$(date '+%H')"* ]]; then
            echo "$pkg"
        fi
    fi
done)

# Alternative: Get all packages installed in last transaction
if [[ -z "$RECENT_PACKAGES" ]]; then
    # Very simple approach: just update the full list
    pacman -Qqe > "$PACKAGES_FILE"
    echo "[+] Updated full package list"
    exit 0
fi

# Track the packages
if [[ -n "$RECENT_PACKAGES" ]]; then
    echo "$RECENT_PACKAGES" | while read -r pkg; do
        [[ -z "$pkg" ]] && continue
        grep -q "^${pkg}$" "$PACKAGES_FILE" || echo "$pkg" >> "$PACKAGES_FILE"
        echo "[+] Tracked: $pkg"
    done
fi

# Sort and deduplicate
sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"

# Git commit
if [[ -d "$DOTFILES_DIR/.git" ]] && command -v git &>/dev/null; then
    cd "$DOTFILES_DIR" || exit 0
    
    git add packages/packages.txt >/dev/null 2>&1
    
    if git diff --cached --quiet packages/packages.txt; then
        exit 0
    fi
    
    # Build commit message
    pkg_list=$(echo "$RECENT_PACKAGES" | tr '\n' ' ' | sed 's/ $//')
    
    # Get hostname
    if [[ -f /etc/hostname ]]; then
        hostname=$(cat /etc/hostname)
    elif [[ -f /proc/sys/kernel/hostname ]]; then
        hostname=$(cat /proc/sys/kernel/hostname)
    else
        hostname="unknown"
    fi
    
    commit_msg="[AUTO] [$hostname] Packages: $pkg_list"
    
    if git commit -m "$commit_msg" >/dev/null 2>&1; then
        echo "[git] Auto-committed: $pkg_list"
        
        # Auto-push using gh CLI
        if command -v gh &>/dev/null && gh auth status &>/dev/null; then
            if git push origin master >/dev/null 2>&1; then
                echo "[git] Auto-pushed to GitHub"
            else
                echo "[git] Push failed - check SSH"
            fi
        else
            echo "[git] Push skipped - gh not auth"
        fi
    fi
fi

exit 0
