#!/bin/bash
# FULLY AUTO Package Tracking - Robust version with machine specs and debugging

# Setup logging
LOG_FILE="/tmp/pkgtrack-$(date +%H%M%S).log"
exec 2>&1 | tee -a "$LOG_FILE"

echo "=== STARTING $(date) ===" 
echo "User: $(whoami), UID: $(id -u)"

# Handle SUDO_USER
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
    echo "SUDO_USER: $SUDO_USER"
fi

# Find dotfiles location (robust)
DOTFILES_DIR=""
for path in "$HOME/Desktop/dotfiles" "$HOME/dotfiles" "$HOME/.dotfiles" "$HOME/Documents/dotfiles"; do
    if [[ -d "$path" ]]; then
        DOTFILES_DIR="$path"
        break
    fi
done

[[ -z "$DOTFILES_DIR" ]] && echo "ERROR: Dotfiles not found" && exit 1
echo "Dotfiles: $DOTFILES_DIR"
PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"

# Ensure packages file exists and is writable
if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Creating packages.txt"
    pacman -Qqe > "$PACKAGES_FILE"
fi

if ! touch "$PACKAGES_FILE.tmp" 2>/dev/null; then
    echo "ERROR: Cannot write to packages.txt"
    exit 1
fi
rm -f "$PACKAGES_FILE.tmp"

# Update package list
OLD_COUNT=$(wc -l < "$PACKAGES_FILE")
pacman -Qqe > "$PACKAGES_FILE"
NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
CHANGE=$((NEW_COUNT - OLD_COUNT))

echo "Packages: $OLD_COUNT → $NEW_COUNT ($CHANGE)"

if [[ $CHANGE -eq 0 ]]; then
    echo "No changes, exit 0"
    exit 0
fi

sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
echo "[+] Updated packages: +$CHANGE packages"

# Git operations
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "Git repo found, proceeding"
    cd "$DOTFILES_DIR" || exit 1
    
    # Get machine specs
    HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
    DATE=$(date '+%Y-%m-%d')
    
    # Machine type
    if ls /sys/class/power_supply/ | grep -q BAT; then
        MACHINE_TYPE="laptop"
    else
        MACHINE_TYPE="desktop"
    fi
    
    # CPU and RAM
    CPU=$(awk '/^model name/{for(i=3;i<=NF;i++)printf "%s ", $i; print ""}' /proc/cpuinfo | head -1)
    RAM=$(free -h | awk '/^Mem:/{print $2}')
    KERNEL=$(uname -r)
    
    echo "Machine: $HOSTNAME ($MACHINE_TYPE)"
    echo "Specs: $CPU, ${RAM} RAM, $KERNEL"
    
    # Git add
    echo "Git add..."
    git add packages/packages.txt
    
    if git diff --cached --quiet packages/packages.txt; then
        echo "No git changes"
        exit 0
    fi
    
    echo "Git changes detected"
    
    NEW_PKG_COUNT=$(git diff --cached packages/packages.txt | grep "^+" | grep -v "^+++" | wc -l)
    
    # Build commit message
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE_TYPE] Packages: +$NEW_PKG_COUNT

Machine Specs: $CPU, ${RAM} RAM, Kernel $KERNEL
Change: $OLD_COUNT → $NEW_COUNT packages"

    echo "Committing..."
    if git commit -m "$COMMIT_MSG"; then
        echo "[git] Auto-committed: +$NEW_PKG_COUNT packages"
        
        # Push via gh CLI
        if command -v gh &>/dev/null; then
            echo "gh CLI available"
            if gh auth status &>/dev/null; then
                echo "gh auth OK, pushing..."
                if git push origin master; then
                    echo "[git] Auto-pushed to GitHub ✅"
                else
                    echo "[git] Push failed"
                fi
            else
                echo "[git] gh not authenticated"
            fi
        else
            echo "[git] gh CLI not available"
        fi
    else
        echo "[git] Commit failed"
    fi
else
    echo "ERROR: No git repo"
fi

echo "=== ENDING ==="
exit 0
