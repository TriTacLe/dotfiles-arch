#!/bin/bash
# Install pacman hook system-wide for ANY PC setup
# Resolves the dotfiles location from this script's path so it works
# regardless of where the repo is cloned.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/config.sh"

PKGTRACK="$DOTFILES_DIR/scripts/pkgtrack.sh"
SYMLINK="/usr/local/bin/dotfiles-pkgtrack"
HOOK_SRC="$DOTFILES_DIR/pacman-hook-autotrack.hook"
HOOK_DST="/usr/share/libalpm/hooks/20-dotfiles-autotrack.hook"

[[ -f "$PKGTRACK" ]]  || { err "$PKGTRACK not found"; exit 1; }
[[ -f "$HOOK_SRC" ]]  || { err "$HOOK_SRC not found"; exit 1; }

sudo ln -sf "$PKGTRACK" "$SYMLINK"
sudo chmod +x "$SYMLINK"
ok "symlink: $SYMLINK -> $PKGTRACK"

sudo install -m 644 "$HOOK_SRC" "$HOOK_DST"
ok "hook installed: $HOOK_DST"

echo ""
info "Auto-tracking is active. Test with: sudo pacman -S --needed hello"
info "Uninstall with: sudo rm $SYMLINK $HOOK_DST"
