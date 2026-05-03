#!/bin/bash
# Verify the dotfiles repo is in a healthy, portable state.
# Run before committing structural changes or before deploying to a fresh PC.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

PASS=0
FAIL=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  ok   $name"
        PASS=$((PASS+1))
    else
        echo "  FAIL $name"
        FAIL=$((FAIL+1))
    fi
}

echo "=== Dotfiles verification ==="

echo ""
echo "[1] Hardcoded user paths"
# /home/<user> hardcodes outside of intentional fallback search lists or archive
HARDCODES=$(grep -rn "/home/tri" \
    --include="*.sh" --include="*.hook" --include=".zshrc" --include="Makefile" \
    --exclude-dir=archived-scripts --exclude-dir=claude-config --exclude-dir=.git . 2>/dev/null | wc -l)
if [[ "$HARDCODES" -eq 0 ]]; then
    echo "  ok   no /home/tri hardcodes"
    PASS=$((PASS+1))
else
    echo "  FAIL $HARDCODES /home/tri hardcode(s) found:"
    grep -rn "/home/tri" --include="*.sh" --include="*.hook" --include=".zshrc" --include="Makefile" \
        --exclude-dir=archived-scripts --exclude-dir=claude-config --exclude-dir=.git . 2>/dev/null | sed 's/^/    /'
    FAIL=$((FAIL+1))
fi

echo ""
echo "[2] Hyprland active hardcodes (monitor names, resolutions)"
ACTIVE_MON=$(grep -rn "^[^#]*monitor.*=.*\(eDP-[0-9]\|DP-[0-9]\)" hypr/ --include="*.conf" 2>/dev/null | wc -l)
ACTIVE_RES=$(grep -rn "^[^#]*\(1920x1200\|2560x1440\)" hypr/ --include="*.conf" 2>/dev/null | wc -l)
[[ "$ACTIVE_MON" -eq 0 ]] && { echo "  ok   no active monitor hardcodes"; PASS=$((PASS+1)); } || { echo "  FAIL $ACTIVE_MON monitor hardcode(s)"; FAIL=$((FAIL+1)); }
[[ "$ACTIVE_RES" -eq 0 ]] && { echo "  ok   no active resolution hardcodes"; PASS=$((PASS+1)); } || { echo "  FAIL $ACTIVE_RES resolution hardcode(s)"; FAIL=$((FAIL+1)); }

echo ""
echo "[3] Shell script syntax"
SH_FAIL=0
while IFS= read -r f; do
    bash -n "$f" 2>/dev/null || { echo "    syntax error: $f"; SH_FAIL=$((SH_FAIL+1)); }
done < <(find . -name "*.sh" -not -path "./archived-scripts/*" -not -path "./claude-config/*" -not -path "./.git/*" -not -path "./nvim/*")
if [[ "$SH_FAIL" -eq 0 ]]; then
    echo "  ok   all shell scripts parse"
    PASS=$((PASS+1))
else
    echo "  FAIL $SH_FAIL script(s) failed to parse"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[4] zsh config syntax"
check "zsh/.zshrc parses" zsh -n zsh/.zshrc

echo ""
echo "[5] Required files exist"
check "scripts/config.sh"            test -f scripts/config.sh
check "scripts/pkgtrack.sh"          test -f scripts/pkgtrack.sh
check "install.sh"                   test -x install.sh
check "install-hook.sh"              test -x install-hook.sh
check "pacman-hook-autotrack.hook"   test -f pacman-hook-autotrack.hook
check "packages/packages.txt"        test -f packages/packages.txt
check "packages/aur.txt"             test -f packages/aur.txt
check ".env.example"                 test -f .env.example

echo ""
echo "[6] Shared library is sourceable"
if bash -c "source scripts/config.sh && [[ -n \$DOTFILES_DIR ]] && type log >/dev/null && type is_stow_package >/dev/null && type list_stow_packages >/dev/null" 2>/dev/null; then
    echo "  ok   config.sh exposes DOTFILES_DIR + helpers"
    PASS=$((PASS+1))
else
    echo "  FAIL config.sh broken or missing helpers"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[7] Pacman hook points at the symlink (machine-agnostic)"
if grep -q "^Exec = /usr/local/bin/dotfiles-pkgtrack" pacman-hook-autotrack.hook 2>/dev/null; then
    echo "  ok   hook uses /usr/local/bin/dotfiles-pkgtrack"
    PASS=$((PASS+1))
else
    echo "  FAIL hook does not point at the symlink"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[8] install.sh --help works"
check "install.sh --help" bash install.sh --help

echo ""
echo "[9] Stow detection finds expected packages"
PKG_COUNT=$(bash -c "source scripts/config.sh && list_stow_packages | wc -l" 2>/dev/null || echo 0)
if [[ "$PKG_COUNT" -ge 5 ]]; then
    echo "  ok   list_stow_packages found $PKG_COUNT package(s)"
    PASS=$((PASS+1))
else
    echo "  FAIL list_stow_packages found only $PKG_COUNT (expected 5+)"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== Result ==="
echo "  passed: $PASS"
echo "  failed: $FAIL"
if [[ "$FAIL" -eq 0 ]]; then
    echo "ALL CHECKS PASSED"
    exit 0
else
    echo "$FAIL CHECK(S) FAILED"
    exit 1
fi
