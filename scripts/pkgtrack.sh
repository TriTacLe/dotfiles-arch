#!/bin/bash
# Fully automated package tracking with actual package names

# Setup logging
LOG_FILE="/tmp/pkgtrack-$(date +%H%M%S).log"
exec 2>&1 | tee -a "$LOG_FILE"
echo "=== STARTING $(date) ==="

# Handle SUDO_USER
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Find dotfiles location
DOTFILES_DIR=""
for path in "$HOME/Desktop/dotfiles" "$HOME/dotfiles" "$HOME/.dotfiles" "$HOME/Documents/dotfiles"; do
    if [[ -d "$path" ]]; then
        DOTFILES_DIR="$path"
        break
    fi
done

[[ -z "$DOTFILES_DIR" ]] && echo "ERROR: Dotfiles not found" && exit 1
PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"

# Ensure packages file exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    pacman -Qqe > "$PACKAGES_FILE"
fi

# Update package list
OLD_COUNT=$(wc -l < "$PACKAGES_FILE")
pacman -Qqe > "$PACKAGES_FILE"
NEW_COUNT=$(wc -l < "$PACKAGES_FILE")

if [[ $NEW_COUNT -eq $OLD_COUNT ]]; then
    echo "No changes, exit 0"
    exit 0
fi

# Get actual package names (the ones that changed)
NEW_PACKAGES=$(git diff "$PACKAGES_FILE" 2>/dev/null | grep "^+" | grep -v "^+++" || echo "unknown")
SORTED_PACKAGES=$(echo "$NEW_PACKAGES" | sort)
PACKAGE_NAMES=$(echo "$SORTED_PACKAGES" | sed 's/^+//' | tr '\n' ' ' | sed 's/^ *//;s/ *$//')

sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
CHANGE=$((NEW_COUNT - OLD_COUNT))
echo "Packages: +$CHANGE: $PACKAGE_NAMES"

# Git operations
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    cd "$DOTFILES_DIR" || exit 1
    
    # Get basic machine info
    HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
    DATE=$(date '+%Y-%m-%d')
    
    # Get only important specs
    CPU=$(awk '/^model name/{print $3, $4, $5}' /proc/cpuinfo | head -1)
    RAM=$(free -h | awk '/^Mem:/{print $2}')
    
    # Machine type
    [[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
    
    # Build commit message with actual package names
    if [[ -n "$PACKAGE_NAMES" ]]; then
        COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $PACKAGE_NAMES"
    else
        COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: unknown"
    fi
    
    echo "Committing with package names..."
    
    git add packages/packages.txt
    
    if ! git diff --cached --quiet packages/packages.txt; then
        if git commit -m "$COMMIT_MSG"; then
            echo "[git] Auto-committed: $PACKAGE_NAMES"
            
            # Push via gh CLI
            if command -v gh &>/dev/null && gh auth status &>/dev/null; then
                if git push origin master; then
                    echo "[git] Auto-pushed to GitHub ✅"
                else
                    echo "[git] Push failed - check SSH"
                fi
            fi
        fi
    fi
fi

echo "=== ENDING ==="
exit 0
