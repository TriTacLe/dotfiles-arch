#!/bin/bash

# =============================================================================
# Dotfiles Test Suite
# =============================================================================
# Run this before pushing to ensure everything works
# =============================================================================

# Don't use set -e - we want to collect all test results

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Test 1: Syntax check install.sh
test_syntax() {
    log_info "Checking install.sh syntax..."
    if bash -n install.sh 2>&1; then
        log_pass "install.sh syntax is valid"
    else
        log_fail "install.sh has syntax errors"
    fi
}

# Test 2: .stow-local-ignore is correct
test_stow_ignore() {
    log_info "Checking .stow-local-ignore..."
    
    local errors=0
    
    # Check for ^\.git pattern
    if ! grep -q "^\\^\\\\.git" .stow-local-ignore; then
        log_fail "Missing ^\\.git pattern in .stow-local-ignore"
        ((errors++))
    fi
    
    # Check for ^\.github pattern
    if ! grep -q "^\\^\\\\.github" .stow-local-ignore; then
        log_fail "Missing ^\\.github pattern in .stow-local-ignore"
        ((errors++))
    fi
    
    # Check for dangerous patterns (without ^ anchor)
    if grep -E "^\\\\\.(git|github)/" .stow-local-ignore; then
        log_fail "Found dangerous pattern without ^ anchor"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_pass ".stow-local-ignore is correct"
    fi
}

# Test 3: Package names are valid
test_package_names() {
    log_info "Checking package names..."
    
    local errors=0
    local invalid_packages=(
        "slack-desktop"  # should be 'slack' in official repos
        "pacseek"        # not a package, it's a stow package
        "cd"             # shell builtin, not a package
        "network-manager-openconnect"  # wrong name
    )
    # Note: visual-studio-code-bin is VALID in AUR
    
    for pkg in "${invalid_packages[@]}"; do
        if grep -r "^${pkg}$" packages/*.txt 2>/dev/null; then
            log_fail "Invalid package name found: $pkg"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_pass "No invalid package names found"
    fi
}

# Test 4: All stow packages have files
test_packages_not_empty() {
    log_info "Checking stow packages have content..."
    
    local errors=0
    local packages=(
        alacritty fastfetch ghostty git hypr kitty lazygit
        misc neofetch nvim nwg-dock nwg-look pacseek
        starship swaync tmux waybar wlogout wofi zathura zsh
    )
    
    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            local count=$(find "$pkg" -type f 2>/dev/null | wc -l)
            if [[ $count -eq 0 ]]; then
                log_fail "Package $pkg is EMPTY"
                ((errors++))
            fi
        else
            log_fail "Package $pkg directory missing"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_pass "All stow packages have content"
    fi
}

# Test 5: No .git directory would be stowed
test_no_git_stow() {
    log_info "Checking .git won't be stowed..."
    
    # Check .stow-local-ignore has proper patterns
    if grep -q "^\\^\\\\.git" .stow-local-ignore; then
        log_pass ".git is properly ignored"
    else
        log_fail ".git pattern missing in .stow-local-ignore"
    fi
}

# Test 6: AUR packages in aur.txt
test_aur_packages() {
    log_info "Checking AUR packages are in aur.txt..."
    
    local aur_pkgs=(
        "zsh-theme-powerlevel10k"
        "zsh-defer"
        "catppuccin-gtk-theme-mocha"
        "visual-studio-code-bin"
    )
    
    local errors=0
    for pkg in "${aur_pkgs[@]}"; do
        if ! grep -q "^${pkg}" packages/aur.txt; then
            log_fail "AUR package $pkg not found in aur.txt"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_pass "AUR packages properly listed"
    fi
}

# Test 7: zshrc guards
test_zshrc_guards() {
    log_info "Checking zshrc has guards..."
    
    local errors=0
    
    # Check for deno guard
    if ! grep -q '\[\[ -f "\$HOME/.deno/env" \]\]' zsh/.zshrc; then
        log_fail "Missing guard for deno"
        ((errors++))
    fi
    
    # Check for openclaw guard
    if ! grep -q 'openclaw' zsh/.zshrc; then
        log_fail "Missing guard for openclaw"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_pass "zshrc has proper guards"
    fi
}

# Test 8: No hardcoded /home/tri paths
test_no_hardcoded_paths() {
    log_info "Checking for hardcoded paths..."
    
    local hardcoded_count=$(grep -c "/home/tri" zsh/.zshrc 2>/dev/null || echo "0")
    
    if [[ $hardcoded_count -gt 0 ]]; then
        log_fail "Found $hardcoded_count hardcoded /home/tri paths in zshrc"
        grep -n "/home/tri" zsh/.zshrc | head -5
    else
        log_pass "No hardcoded paths found"
    fi
}

# Test 9: install.sh functions exist
test_install_functions() {
    log_info "Checking install.sh has required functions..."
    
    local required_funcs=(
        "check_not_root"
        "check_arch"
        "install_yay"
        "install_essential"
        "install_packages"
        "stow_packages"
        "post_install"
        "verify"
    )
    
    local errors=0
    for func in "${required_funcs[@]}"; do
        if ! grep -q "^${func}()" install.sh; then
            log_fail "Missing function: $func"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_pass "All required functions present"
    fi
}

# Main
main() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  Dotfiles Test Suite${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    
    test_syntax
    test_stow_ignore
    test_package_names
    test_packages_not_empty
    test_no_git_stow
    test_aur_packages
    test_zshrc_guards
    test_no_hardcoded_paths
    test_install_functions
    
    echo ""
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}Tests Passed: ${TESTS_PASSED:-0}${NC}"
    echo -e "${RED}Tests Failed: ${TESTS_FAILED:-0}${NC}"
    echo -e "${BLUE}=================================${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        echo -e "${GREEN}All tests passed! Ready to push.${NC}"
        exit 0
    fi
}

main "$@"
