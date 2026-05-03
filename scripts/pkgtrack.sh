#!/bin/bash
# Package tracking - regenerates packages.txt + aur.txt from pacman -Qqe,
# then commits/pushes only if AUTO_PUSH=true (default).
# Invoked by /usr/share/libalpm/hooks/20-dotfiles-autotrack.hook
# via the /usr/local/bin/dotfiles-pkgtrack symlink.

# Handle SUDO_USER (pacman runs as root - rebase HOME so config.sh and git work)
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
fi

# Source shared library: DOTFILES_DIR resolution, logger, settings.
# When invoked via the symlink, BASH_SOURCE points at the real pkgtrack.sh
# inside the dotfiles repo, so this resolves correctly.
_self="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
source "$(dirname "$_self")/config.sh"
unset _self

[[ -z "$DOTFILES_DIR" ]] && { echo "[pkgtrack] dotfiles dir not found" >&2; exit 1; }
PACKAGES_FILE="$PACKAGES_DIR/packages.txt"
AUR_FILE="$PACKAGES_DIR/aur.txt"

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

# Skip the whole git dance if nothing actually changed.
if [[ "$NEW_PKGS" == "none" && "$NEW_AUR" == "none" ]]; then
    exit 0
fi

echo "Committing package changes..."
echo "Official packages: $NEW_COUNT"
echo "AUR packages: $AUR_COUNT"
echo "Commit message: $COMMIT_MSG"

# Run git as the real user so commit identity / ssh keys are correct.
git_as_user() {
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" git "$@"
    else
        git "$@"
    fi
}

git_as_user add packages/packages.txt packages/aur.txt
# `git commit` returns nonzero when there's nothing to commit - that's not a failure.
git_as_user commit -m "$COMMIT_MSG" || { echo "[pkgtrack] nothing to commit"; exit 0; }

if [[ "$AUTO_PUSH" == "true" ]]; then
    if git_as_user push 2>/dev/null; then
        echo "Pushed successfully"
    else
        echo "[pkgtrack] push failed (offline or no remote) - committed locally"
    fi
else
    echo "[pkgtrack] AUTO_PUSH=false - committed locally, skipping push"
fi

exit 0