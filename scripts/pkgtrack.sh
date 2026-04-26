#!/bin/bash
# Package tracking - Use gh CLI for EVERYTHING (commit + push)

# Handle SUDO_USER
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
    echo "SUDO_USER: $SUDO_USER"
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
    echo "No changes, exit 0"
    exit 0
fi

sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
echo "[+] Updated package list: $OLD_COUNT -$NEW_COUNT"

# Try to get package names from hook argument (clean up whitespace)
NEW_PKGS="new-packages"
if [[ -n "$1" ]]; then
    # Remove newlines and extra spaces
    NEW_PKGS=$(echo "$1" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
fi

# Use gh CLI for ALL git operations (works as root with your authentication)
cd "$DOTFILES_DIR" || exit 1

HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d')
[[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
CPU=$(awk '/^model name/{print $3" " " $4 " " $5}' /proc/cpuinfo | head -1 | sed 's/  */ /g' 2>/dev/null || echo "unknown")

COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $NEW_PKGS"

echo "Using gh CLI for all git operations..."
echo "Commit message: $COMMIT_MSG"

# Use gh CLI to do everything (works as root)
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    # Use gh CLI for add + commit + push
    echo "gh repo sync"
    gh repo sync -c "$COMMIT_MSG" 2>&1 | head -10
else
    echo "gh CLI not available!"
fi

exit 0
