#!/bin/bash
# Shared dotfiles library. Source this from any script that needs:
#   - DOTFILES_DIR resolution (env var > common locations)
#   - Stow package detection / exclusion list
#   - Color logger functions
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
#   # or, when sourcing from outside scripts/:
#   DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$DOTFILES_DIR/scripts/config.sh"

# ────────────────────────────────────────────
# DOTFILES_DIR resolution
# ────────────────────────────────────────────
# Priority:
#   1. $DOTFILES_DIR env var (if set and valid)
#   2. Hostname-specific override (case statement below)
#   3. Search list of common clone locations

if [[ -z "$DOTFILES_DIR" || ! -d "$DOTFILES_DIR/.git" ]]; then
    case "${HOSTNAME:-$(hostname 2>/dev/null)}" in
        # Add hostname-specific overrides here, e.g.:
        # work-laptop) DOTFILES_DIR="$HOME/dotfiles" ;;
        *) ;;
    esac
fi

if [[ -z "$DOTFILES_DIR" || ! -d "$DOTFILES_DIR/.git" ]]; then
    for _path in \
        "$HOME/Desktop/projects/dotfiles" \
        "$HOME/Desktop/dotfiles" \
        "$HOME/dotfiles" \
        "$HOME/.dotfiles" \
        "$HOME/Documents/dotfiles" \
        "$HOME/projects/dotfiles"; do
        if [[ -d "$_path/.git" ]]; then
            DOTFILES_DIR="$_path"
            break
        fi
    done
    unset _path
fi

PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/packages}"

# ────────────────────────────────────────────
# Stow package detection
# ────────────────────────────────────────────
# These directories are NOT stow packages even though they live at the repo root.
DOTFILES_NON_STOW_DIRS=(
    .git
    .github
    .claude
    archived-scripts
    bin
    claude-config
    packages
    scripts
)

# A directory is a stow package if it contains either a .config/ subtree
# or a top-level dotfile we explicitly support.
DOTFILES_STOW_MARKERS=(
    .config
    .zshrc
    .tmux.conf
    .gitconfig
    .gitignore_global
)

# is_stow_package <dir> -> 0 if yes, 1 if no
is_stow_package() {
    local pkg="$1"
    [[ -d "$pkg" ]] || return 1
    local name="${pkg##*/}"
    name="${name%/}"

    local skip
    for skip in "${DOTFILES_NON_STOW_DIRS[@]}"; do
        [[ "$name" == "$skip" ]] && return 1
    done

    local marker
    for marker in "${DOTFILES_STOW_MARKERS[@]}"; do
        [[ -e "$pkg/$marker" ]] && return 0
    done
    return 1
}

# list_stow_packages -> prints one package name per line
list_stow_packages() {
    local d
    for d in "$DOTFILES_DIR"/*/; do
        if is_stow_package "$d"; then
            local name="${d%/}"
            echo "${name##*/}"
        fi
    done
}

# ────────────────────────────────────────────
# Color logger
# ────────────────────────────────────────────
# Defined as functions so they're cheap and don't pollute namespace with
# raw escape codes. Respect NO_COLOR env var.

_dotfiles_color() {
    if [[ -n "$NO_COLOR" || ! -t 1 ]]; then
        printf "%s" "$2"
    else
        printf "\033[%sm%s\033[0m" "$1" "$2"
    fi
}

log()   { echo "$(_dotfiles_color '0;34' '[install]') $*"; }
ok()    { echo "$(_dotfiles_color '0;32' '[ok]') $*"; }
warn()  { echo "$(_dotfiles_color '1;33' '[warn]') $*"; }
err()   { echo "$(_dotfiles_color '0;31' '[error]') $*" >&2; }
info()  { echo "$(_dotfiles_color '0;36' '[info]') $*"; }

# ────────────────────────────────────────────
# Settings (overridable via env)
# ────────────────────────────────────────────
MACHINE_TYPE="${MACHINE_TYPE:-auto}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-master}"
AUTO_PUSH="${AUTO_PUSH:-true}"

export DOTFILES_DIR PACKAGES_DIR MACHINE_TYPE GIT_REMOTE GIT_BRANCH AUTO_PUSH
