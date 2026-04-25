#!/bin/bash
# Package Tracking Script - Track manually installed packages
# Usage: pkgtrack [add|list|diff]

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Desktop/dotfiles}"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get all installed packages (explicitly installed, not as dependencies)
get_explicit_packages() {
    pacman -Qeq 2>/dev/null || yay -Qeq 2>/dev/null
}

# Get packages currently tracked in dotfiles
get_tracked_packages() {
    cat "$PACKAGES_DIR"/*.txt 2>/dev/null | grep -v '^#' | grep -v '^$' | sort | uniq
}

# Compare and show new packages
show_diff() {
    echo -e "${BLUE}[pkgtrack]${NC} Comparing installed vs tracked packages..."

    local installed=$(get_explicit_packages | sort)
    local tracked=$(get_tracked_packages)

    # Find packages installed but not tracked
    local new_packages=$(comm -23 <(echo "$installed") <(echo "$tracked"))

    if [[ -z "$new_packages" ]]; then
        echo -e "${GREEN}[ok]${NC} No new packages to track"
        return 0
    fi

    echo -e "${YELLOW}[new]${NC} Found packages to track:"
    echo "$new_packages" | while read pkg; do
        # Check if from AUR
        if yay -Qi "$pkg" &>/dev/null 2>&1; then
            echo "  - $pkg (AUR)"
        else
            echo "  - $pkg"
        fi
    done

    echo ""
    echo "Add these to packages/*.txt? [y/N]: "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        add_new_packages
    fi
}

# Automatically add new packages to appropriate category
add_new_packages() {
    local installed=$(get_explicit_packages | sort)
    local tracked=$(get_tracked_packages)
    local new_packages=$(comm -23 <(echo "$installed") <(echo "$tracked"))

    local aur_pkgs=""
    local dev_pkgs=""
    local desktop_pkgs=""
    local terminal_pkgs=""
    local core_pkgs=""
    local apps_pkgs=""

    echo "$new_packages" | while read pkg; do
        # Skip if already added in this run
        grep -q "^${pkg}$" "$PACKAGES_DIR"/*.txt 2>/dev/null && continue

        # Find which category it belongs to
        # AUR packages
        if yay -Qi "$pkg" &>/dev/null 2>&1; then
            aur_pkgs="$aur_pkgs\n$pkg"
        # Development
        elif echo "$pkg" | grep -E "(docker|git|node|python|go|java|rust|cmake|clang|build|devel)" >/dev/null; then
            dev_pkgs="$dev_pkgs\n$pkg"
        # Desktop/Wayland
        elif echo "$pkg" | grep -E "(hypr|waybar|wofi|sway|pk|xdg|kde|gnome|plasma)" >/dev/null; then
            desktop_pkgs="$desktop_pkgs\n$pkg"
        # Terminal
        elif echo "$pkg" | grep -E "(vim|nvim|tmux|fzf|eza|bat|starship|zsh|shell|term)" >/dev/null; then
            terminal_pkgs="$terminal_pkgs\n$pkg"
        # Applications
        elif echo "$pkg" | grep -E "(firefox|brave|chrom|slack|spotify|obsidian|libreoffice|code|ide)" >/dev/null; then
            apps_pkgs="$apps_pkgs\n$pkg"
        # Core
        else
            core_pkgs="$core_pkgs\n$pkg"
        fi
    done

    # Add to files
    if [[ -n "$aur_pkgs" ]]; then
        echo -e "$aur_pkgs" >> "$PACKAGES_DIR/aur.txt"
        echo -e "${GREEN}[+]${NC} Added AUR packages to aur.txt"
    fi

    if [[ -n "$dev_pkgs" ]]; then
        echo -e "$dev_pkgs" >> "$PACKAGES_DIR/development.txt"
        echo -e "${GREEN}[+]${NC} Added dev packages to development.txt"
    fi

    if [[ -n "$desktop_pkgs" ]]; then
        echo -e "$desktop_pkgs" >> "$PACKAGES_DIR/desktop.txt"
        echo -e "${GREEN}[+]${NC} Added desktop packages to desktop.txt"
    fi

    if [[ -n "$terminal_pkgs" ]]; then
        echo -e "$terminal_pkgs" >> "$PACKAGES_DIR/terminal.txt"
        echo -e "${GREEN}[+]${NC} Added terminal packages to terminal.txt"
    fi

    if [[ -n "$apps_pkgs" ]]; then
        echo -e "$apps_pkgs" >> "$PACKAGES_DIR/applications.txt"
        echo -e "${GREEN}[+]${NC} Added applications to applications.txt"
    fi

    if [[ -n "$core_pkgs" ]]; then
        echo -e "$core_pkgs" >> "$PACKAGES_DIR/core.txt"
        echo -e "${GREEN}[+]${NC} Added core packages to core.txt"
    fi

    echo ""
    echo -e "${GREEN}[ok]${NC} Packages tracked successfully!"
    echo "Review and commit: cd ~/Desktop/dotfiles && git add packages/ && git commit"
}

# List tracked packages
list_tracked() {
    echo -e "${BLUE}[pkgtrack]${NC} Currently tracked packages:"
    echo "Core: $(get_tracked_packages | wc -l)"
    get_tracked_packages
}

# Main
case "${1:-diff}" in
    add|--add)
        show_diff
        ;;
    list|--list)
        list_tracked
        ;;
    diff|--diff)
        show_diff
        ;;
    *)
        echo "Usage: $0 [add|list|diff]"
        echo ""
        echo "Commands:"
        echo "  add   - Show and add new packages"
        echo "  list  - List currently tracked packages"
        echo "  diff  - Show difference between installed and tracked"
        ;;
esac