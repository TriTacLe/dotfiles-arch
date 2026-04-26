#!/bin/bash
# Simple Package Tracking - ONE file, NO complexity, SAFE for production

# Safety check: ensure we can write to files
if ! touch /tmp/pkgtrack-test.$$ 2>/dev/null; then
    echo "[ERROR] Cannot write to files - aborting"
    exit 1
fi
rm -f /tmp/pkgtrack-test.$$

# Handle SUDO_USER (pacman runs as root)
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Find dotfiles location (with multiple fallbacks)
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

# Safety check: ensure dotfiles found
if [[ -z "$DOTFILES_DIR" ]]; then
    echo "[ERROR] Dotfiles directory not found"
    echo "[INFO] Tried: ${DOTFILES_LOCATIONS[*]}"
    exit 1
fi

PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"

# Create packages file if not exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    pacman -Qqe > "$PACKAGES_FILE"
fi

# Ensure we can write to this file
if ! touch "$PACKAGES_FILE.$$" 2>/dev/null; then
    echo "[ERROR] Cannot write to $PACKAGES_FILE"
    exit 1
fi
rm -f "$PACKAGES_FILE.$$"

# Get packages from pacman hook or recent installs
if [[ -n "$H_PKGNAME" ]]; then
    PACKAGES="$H_PKGNAME"
else
    # Add all current packages (simple approach)
    pacman -Qqe > "$PACKAGES_FILE"
    PACKAGES="full_update"
fi

# Actually track the packages
if [[ "$PACKAGES" == "full_update" ]]; then
    echo "[+] Updated full package list"
else
    # Add new packages to list
    echo "$PACKAGES" | while read -r pkg; do
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
    pkg_list=$(echo "$PACKAGES" | tr '\n' ' ' | sed 's/ $//')
    
    # Get hostname (works as root)
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
