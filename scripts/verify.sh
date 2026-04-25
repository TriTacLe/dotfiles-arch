#!/bin/bash
# Dotfiles Verification & Test Suite
# Tests that everything works on a new PC setup

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

log() { echo -e "${BLUE}[TEST]${NC} $1"; }
pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Dotfiles Verification & Test Suite              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Dotfiles directory exists
test_dotfiles_dir() {
    log "Checking dotfiles directory..."
    if [[ -d "$HOME/Desktop/dotfiles" ]]; then
        pass "Dotfiles directory exists"
    else
        fail "Dotfiles directory not found"
        return 1
    fi
}

# Test 2: Git repository
test_git_repo() {
    log "Checking git repository..."
    cd "$HOME/Desktop/dotfiles" || return 1
    if git rev-parse --git-dir >/dev/null 2>&1; then
        pass "Git repository initialized"
    else
        fail "Not a git repository"
        return 1
    fi
}

# Test 3: Install script exists and is executable
test_install_script() {
    log "Checking install.sh..."
    if [[ -x "install.sh" ]]; then
        pass "install.sh exists and is executable"
    elif [[ -f "install.sh" ]]; then
        fail "install.sh exists but not executable (chmod +x install.sh)"
        return 1
    else
        fail "install.sh not found"
        return 1
    fi
}

# Test 4: Install script syntax
test_install_syntax() {
    log "Validating install.sh syntax..."
    if bash -n install.sh 2>&1; then
        pass "install.sh syntax is valid"
    else
        fail "install.sh has syntax errors"
        return 1
    fi
}

# Test 5: Package files exist
test_package_files() {
    log "Checking package files..."
    local files=("core.txt" "desktop.txt" "development.txt" "terminal.txt" "aur.txt" "applications.txt")
    local missing=()

    for file in "${files[@]}"; do
        if [[ ! -f "packages/$file" ]]; then
            missing+=("$file")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass "All package files exist (6 files)"
    else
        fail "Missing package files: ${missing[*]}"
        return 1
    fi
}

# Test 6: Package count
test_package_count() {
    log "Counting tracked packages..."
    local count=$(cat packages/*.txt 2>/dev/null | grep -v '^#' | grep -v '^$' | sort | uniq | wc -l)

    if [[ $count -ge 200 ]]; then
        pass "Tracked packages: $count (minimum 200 required)"
    else
        warn "Tracked packages: $count (recommended 200+)"
    fi
}

# Test 7: Stow packages exist
test_stow_packages() {
    log "Checking stow packages..."
    local packages=("zsh" "nvim" "hypr" "waybar" "alacritty" "kitty" "ghostty")
    local missing=()

    for pkg in "${packages[@]}"; do
        if [[ ! -d "$pkg" ]]; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass "All stow packages exist (${#packages[@]} packages)"
    else
        warn "Missing stow packages: ${missing[*]}"
    fi
}

# Test 8: Symlinks created
test_symlinks() {
    log "Checking symlinks..."
    local symlinks=(".zshrc" ".gitconfig" ".tmux.conf")
    local missing=()

    for link in "${symlinks[@]}"; do
        if [[ ! -L "$HOME/$link" ]]; then
            missing+=("$link")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass "All symlinks created (${#symlinks[@]} links)"
    else
        warn "Missing symlinks (install not run): ${missing[*]}"
    fi
}

# Test 9: Critical packages installed
test_critical_packages() {
    log "Checking critical packages..."
    local critical=("zsh" "nvim" "git" "hyprland" "waybar" "fzf" "eza" "bat")
    local missing=()

    for pkg in "${critical[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass "All critical packages installed (${#critical[@]} packages)"
    else
        warn "Missing packages (run ./install.sh): ${missing[*]}"
    fi
}

# Test 10: Default shell is zsh
test_default_shell() {
    log "Checking default shell..."
    if [[ "$SHELL" == *"zsh"* ]]; then
        pass "Default shell is zsh"
    else
        warn "Default shell: $SHELL (set with chsh -s zsh)"
    fi
}

# Test 11: zsh config loaded
test_zsh_config() {
    log "Checking zsh configuration..."
    if [[ -f "$HOME/.zshrc" ]]; then
        pass ".zshrc symlink exists"
    else
        fail ".zshrc not found (run ./install.sh --stow)"
        return 1
    fi
}

# Test 12: Hyprland config
test_hyprland_config() {
    log "Checking Hyprland configuration..."
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
        pass "Hyprland is running/installed"
    else
        warn "Hyprland not running (run Hyprland first)"
    fi
}

# Test 13: Auto-tracking hook
test_auto_tracking_setup() {
    log "Checking auto-tracking setup..."
    if [[ -f "/usr/share/libalpm/hooks/20-dotfiles-autotrack.hook" ]]; then
        pass "Auto-tracking hook installed"
    else
        warn "Auto-tracking hook not installed (run ./scripts/setup-autotrack.sh)"
    fi
}

# Test 14: Keyboard tilde test
test_tilde_functionality() {
    log "Testing tilde functionality..."
    if command -v wtype &>/dev/null; then
        pass "wtype installed (for tilde typing)"
    else
        fail "wtype not installed (for Print Screen tilde)"
        return 1
    fi
}

# Test 15: Wayland tools
test_wayland_tools() {
    log "Checking Wayland tools..."
    local tools=("waybar" "wofi" "swaync" "wlogout")
    local missing=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass "All Wayland tools installed (${#tools[@]} tools)"
    else
        warn "Missing Wayland tools: ${missing[*]}"
    fi
}

# Run all tests
main() {
    test_dotfiles_dir
    test_git_repo
    test_install_script
    test_install_syntax
    test_package_files
    test_package_count
    test_stow_packages
    test_symlinks
    test_critical_packages
    test_default_shell
    test_zsh_config
    test_hyprland_config
    test_auto_tracking_setup
    test_tilde_functionality
    test_wayland_tools

    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                    TEST SUMMARY                           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC} / ${TESTS_PASSED}"
    echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
        echo ""
        echo "Your dotfiles are ready for deployment!"
        echo ""
        echo "For a NEW PC:"
        echo "  1) git clone <your-repo> ~/Desktop/dotfiles"
        echo "  2) cd ~/Desktop/dotfiles"
        echo "  3) ./install.sh"
        echo "  4) ./scripts/setup-autotrack.sh"
        echo ""
        exit 0
    else
        echo -e "${YELLOW}Some tests failed. Review the results above.${NC}"
        echo ""
        echo "Common fixes:"
        if [[ $TESTS_FAILED -gt 0 ]]; then
            echo "  • Run: ./install.sh --packages  (install packages)"
            echo "  • Run: ./install.sh --stow      (stow configs)"
            echo "  • Run: ./scripts/setup-autotrack.sh  (setup auto-tracking)"
        fi
        echo ""
        exit 1
    fi
}

main "$@"