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

# Save old list to temp file
OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

# Update package list
pacman -Qqe > "$PACKAGES_FILE"
sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"

# Detect new packages (only in new file)
NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
rm -f "$OLD_PACKAGES_FILE"

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
[[ -n "$NEW_PKGS" ]] && echo "[+] New packages: $NEW_PKGS" || NEW_PKGS="updated"

cd "$DOTFILES_DIR" || exit 1

HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d')
[[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
CPU=$(awk '/^model name/{print $3 " " $4 " " $5}' /proc/cpuinfo | head -1 | sed 's/  */ /g' 2>/dev/null || echo "unknown")

COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $NEW_PKGS"

echo "Using gh CLI for all git operations..."
echo "Commit message: $COMMIT_MSG"

if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    git add packages/packages.txt
    git commit -m "$COMMIT_MSG"
    git push
    echo "Pushed successfully"
else
    echo "gh CLI not available or not authenticated!"
fi

exit 0