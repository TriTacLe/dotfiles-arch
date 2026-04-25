#!/bin/bash
# Auto-track packages - APPENDS to dotfiles package lists
# Runs after pacman transactions via hook
# WORKS FOR ANY USER - No hardcoded paths!

# Auto-detect dotfiles location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PACKAGES_DIR="$DOTFILES_DIR/packages"
AUTO_PACKAGES="$PACKAGES_DIR/auto-tracked.txt"

# Create auto-tracked file if not exists
[[ ! -f "$AUTO_PACKAGES" ]] && touch "$AUTO_PACKAGES"

# Get packages from this transaction (from pacman hook environment)
if [[ -n "$H_PKGNAME" ]]; then
    PACKAGES="$H_PKGNAME"
else
    # Fallback: get recently installed packages (last 5 minutes)
    PACKAGES=$(pacman -Qqe 2>/dev/null | while read pkg; do
        if pacman -Qi "$pkg" 2>/dev/null | grep -A 5 "Install Date" | grep -q "$(date '+%Y-%m-%d %H')" 2>/dev/null; then
            echo "$pkg"
        fi
    done)
fi

# APPEND each new package if not already tracked
echo "$PACKAGES" | while read -r pkg; do
    [[ -z "$pkg" ]] && continue

    # Skip if already tracked in any package file
    grep -q "^${pkg}$" "$PACKAGES_DIR"/*.txt 2>/dev/null && continue

    # Categorize and APPEND to appropriate file
    if yay -Qi "$pkg" &>/dev/null 2>&1; then
        echo "$pkg" >> "$PACKAGES_DIR/aur.txt" && echo "[+] $pkg -> aur.txt (AUR)"
    elif echo "$pkg" | grep -E "(docker|git|node|python|go|java|rust|cmake|clang|build|devel)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/development.txt" || echo "$pkg" >> "$PACKAGES_DIR/development.txt" && echo "[+] $pkg -> development.txt"
    elif echo "$pkg" | grep -E "(hypr|waybar|wofi|sway|pk|xdg|kde|gnome|plasma)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/desktop.txt" || echo "$pkg" >> "$PACKAGES_DIR/desktop.txt" && echo "[+] $pkg -> desktop.txt"
    elif echo "$pkg" | grep -E "(vim|nvim|tmux|fzf|eza|bat|starship|zsh|shell|term|wev|wtype)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/terminal.txt" || echo "$pkg" >> "$PACKAGES_DIR/terminal.txt" && echo "[+] $pkg -> terminal.txt"
    elif echo "$pkg" | grep -E "(firefox|brave|chrom|slack|spotify|obsidian|libreoffice|code|ide)" >/dev/null; then
        grep -q "^${pkg}$" "$PACKAGES_DIR/applications.txt" || echo "$pkg" >> "$PACKAGES_DIR/applications.txt" && echo "[+] $pkg -> applications.txt"
    else
        grep -q "^${pkg}$" "$PACKAGES_DIR/core.txt" || echo "$pkg" >> "$PACKAGES_DIR/core.txt" && echo "[+] $pkg -> core.txt"
    fi
done

# Sort all package files to keep them clean
for file in "$PACKAGES_DIR"/*.txt; do
    temp_file=$(mktemp)
    sort -u "$file" > "$temp_file"
    mv "$temp_file" "$file"
done

# Auto-commit and push to GitHub (if git repo exists)
if [[ -d "$DOTFILES_DIR/.git" ]] && command -v git &>/dev/null; then
    cd "$DOTFILES_DIR"

    # Add package changes
    git add packages/*.txt >/dev/null 2>&1

    # Check if there are changes to commit
    if git diff --cached --quiet packages/; then
        # No changes, skip commit
        exit 0
    fi

    # Create structured commit message
    local pkg_list=$(echo "$PACKAGES" | tr '\n' ' ' | sed 's/ $//')
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local commit_msg="[AUTO] 🤖 Tracked packages: $pkg_list"

    # Commit changes
    if git commit -m "$commit_msg" >/dev/null 2>&1; then
        echo "[git] ✅ Auto-committed: $pkg_list"

        # Auto-push to GitHub
        if git push >/dev/null 2>&1; then
            echo "[git] 🚀 Auto-pushed to GitHub"
        else
            echo "[git] ⚠️  Auto-push failed (check GitHub auth)"
        fi
    fi
fi

exit 0