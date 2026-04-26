#!/bin/bash
# Package tracking using gh CLI for push

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

[[ -z "$DOTFILES_DIR" ]] && exit 1
PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"

# Get old count
OLD_COUNT=$(wc -l < "$PACKAGES_FILE" 2>/dev/null || echo "0")

# Update package list
pacman -Qqe > "$PACKAGES_FILE"

# Get new count
NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
CHANGE=$((NEW_COUNT - OLD_COUNT))

if [[ $CHANGE -le 0 ]]; then
    exit 0
fi

sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
echo "[+] Updated package list: $OLD_COUNT - $NEW_COUNT (+$CHANGE)"

# Get package name from hook argument
NEW_PKGS=""
if [[ -n "$1" ]]; then
    NEW_PKGS="$1"
elif [[ $CHANGE -lt 5 ]]; then
    NEW_PKGS="new packages"
fi

# Git commit
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    cd "$DOTFILES_DIR" || exit 1
    
    HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
    DATE=$(date '+%Y-%m-%d')
    [[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
    CPU=$(awk '/^model name/{print $3, $4, $5}' /proc/cpuinfo | head -1 2>/dev/null || echo "unknown")
    
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $NEW_PKGS"

    git add packages/packages.txt
    
    if ! git diff --cached --quiet packages/packages.txt; then
        if git commit -m "$COMMIT_MSG"; then
            echo "[git] Auto-committed: $NEW_PKGS"
            
            # Use gh CLI to push (uses your authenticated session)
            if command -v gh &>/dev/null && gh auth status &>/dev/null; then
                if gh repo sync 2>&1; then
                    echo "[git] Auto-pushed to GitHub via gh CLI"
                else
                    echo "[git] gh repo sync failed"
                fi
            fi
        fi
    fi
fi

exit 0
