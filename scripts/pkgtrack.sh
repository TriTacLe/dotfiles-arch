#!/bin/bash
# Package tracking - SIMPLE and WORKING

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

# Get current state (before update)
pacman -Qqe > "$PACKAGES_FILE.tmp1"

# Update to latest state
pacman -Qqe > "$PACKAGES_FILE"
NEW_COUNT=$(wc -l < "$PACKAGES_FILE")

# Find what's new
OLD_COUNT=$(wc -l < "$PACKAGES_FILE.tmp1 2>/dev/null || echo "0")
rm -f "$PACKAGES_FILE.tmp1"

if [[ $NEW_COUNT -le $OLD_COUNT ]]; then
    # No changes or something wrong, skip
    exit 0
fi

# Try to find new packages
NEW_PKGS=$(comm -13 <(sort <(pacman -Siiq python-msgpack ufw borg fail2ban 2>/dev/null | awk '{print $1}')) <(sort "$PACKAGES_FILE")) 2>/dev/null || echo "new_packages")

if [[ "$NEW_PKGS" == *new_packages* ]] || [[ -z "$NEW_PKGS" ]]; then
    # Fallback: Just say new_packages
    PACKAGE_LIST="new_packages"
else
    # Convert to comma-separated
    PACKAGE_LIST=$(echo "$NEW_PKGS" | head -10 | tr '\n' ', ')
fi

sort -u "$PACKAGES_FILE" -o "$PACKAGES_FILE"
CHANGE=$((NEW_COUNT - OLD_COUNT))
echo "[+] Added $CHANGE packages: $PACKAGE_LIST"

# Git operations
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    cd "$DOTFILES_DIR" || exit 1
    
    HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
    DATE=$(date '+%Y-%m-%d')
    [[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"
    CPU=$(awk '/^model name/{print $3, $4, $5}' /proc/cpufile || echo "unknown")
    
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] Packages: $PACKAGE_LIST"
    
    git add packages/packages.txt
    
    if ! git diff --cached --quiet packages/packages.txt; then
        if git commit -m "$COMMIT_MSG"; then
            echo "[git] Auto-committed: $PACKAGE_LIST"
            
            # Push with timeout and error handling
            timeout 10 git push origin master >> /tmp/git-push.log 2>&1 || echo "[git] Push timeout/error"
        fi
    fi
fi

exit 0
