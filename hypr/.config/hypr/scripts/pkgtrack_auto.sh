#!/bin/bash
# Auto-track packages - APPENDS to dotfiles package lists
# Runs after pacman transactions via hook

if [[ -z "$DOTFILES_DIR" || ! -d "$DOTFILES_DIR" ]]; then
    for path in \
        "$HOME/Desktop/dotfiles" \
        "$HOME/dotfiles" \
        "$HOME/.dotfiles" \
        "$HOME/Documents/dotfiles" \
        "$HOME/projects/dotfiles"; do
        if [[ -d "$path/.git" ]]; then
            DOTFILES_DIR="$path"
            break
        fi
    done
fi
[[ -z "$DOTFILES_DIR" ]] && exit 0
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

# Quiet commit (if git repo exists)
if [[ -d "$DOTFILES_DIR/.git" ]] && command -v git &>/dev/null; then
    cd "$DOTFILES_DIR" && git add packages/*.txt >/dev/null 2>&1
    git commit -m "Auto-track: $PACKAGES" >/dev/null 2>&1 && echo "[git] Auto-committed package updates"
fi

exit 0
