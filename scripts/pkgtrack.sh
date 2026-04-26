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
AUR_FILE="$DOTFILES_DIR/packages/aur.txt"

# Function to check if package is in AUR
is_aur_package() {
    pacman -Si "$1" &>/dev/null && return 1 || return 0
}

# Save old lists to temp files
OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

OLD_AUR_FILE=$(mktemp)
cp "$AUR_FILE" "$OLD_AUR_FILE" 2>/dev/null || true

# Get all explicitly installed packages
ALL_PACKAGES=$(pacman -Qqe | sort)

# Separate into official and AUR packages
[[ -f "$PACKAGES_FILE" ]] && > "$PACKAGES_FILE" || touch "$PACKAGES_FILE"
[[ -f "$AUR_FILE" ]] && > "$AUR_FILE" || touch "$AUR_FILE"

for pkg in $ALL_PACKAGES; do
    if is_aur_package "$pkg"; then
        echo "$pkg" >> "$AUR_FILE"
    else
        echo "$pkg" >> "$PACKAGES_FILE"
    fi
done

# Sort and deduplicate
sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
sort -u "$AUR_FILE" -o "$AUR_FILE"

# Detect new packages
NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
NEW_AUR=$(comm -13 <(sort "$OLD_AUR_FILE") "$AUR_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

rm -f "$OLD_PACKAGES_FILE" "$OLD_AUR_FILE"

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
AUR_COUNT=$(wc -l < "$AUR_FILE" 2>/dev/null || echo "0")

[[ -n "$NEW_PKGS" ]] && echo "[+] New official packages: $NEW_PKGS" || NEW_PKGS="none"
[[ -n "$NEW_AUR" ]] && echo "[+] New AUR packages: $NEW_AUR" || NEW_AUR="none"

cd "$DOTFILES_DIR" || exit 1

HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d')
[[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
CPU=$(awk '/^model name/{print $3 " " $4 " " $5}' /proc/cpuinfo | head -1 | sed 's/  */ /g' 2>/dev/null || echo "unknown")

# Build commit message
if [[ "$NEW_AUR" != "none" && "$NEW_PKGS" != "none" ]]; then
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $NEW_PKGS | AUR: $NEW_AUR"
elif [[ "$NEW_AUR" != "none" ]]; then
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] AUR Packages: $NEW_AUR"
else
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $NEW_PKGS"
fi

echo "Committing package changes..."
echo "Official packages: $NEW_COUNT"
echo "AUR packages: $AUR_COUNT"
echo "Commit message: $COMMIT_MSG"

if [[ -n "$SUDO_USER" ]]; then
    sudo -u "$SUDO_USER" git add packages/packages.txt packages/aur.txt
    sudo -u "$SUDO_USER" git commit -m "$COMMIT_MSG"
    sudo -u "$SUDO_USER" git push
else
    git add packages/packages.txt packages/aur.txt
    git commit -m "$COMMIT_MSG"  
    git push
fi
echo "Pushed successfully"

exit 0