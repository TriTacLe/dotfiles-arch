#!/bin/bash
# Production System Verification - Safety Check Before Deploy

echo "=== PRODUCTION SYSTEM VERIFICATION ==="
echo ""

FAILED=0

# 1. Check for active hardcoded monitors
echo "1. Checking for active hardcode monitors..."
ACTIVE_MONITORS=$(grep -rn "monitor.*=.*eDP-[0-9]\|monitor.*=.*DP-[0-9]" hypr/ --include="*.conf" 2>/dev/null | grep -v "#" | wc -l)
if [[ "$ACTIVE_MONITORS" -eq 0 ]]; then
    echo "   ✅ PASS: No active monitor hardcodes"
else
    echo "   ❌ FAIL: Found $ACTIVE_MONITORS active monitor hardcodes"
    FAILED=$((FAILED + 1))
fi

# 2. Check for active hardcoded resolutions
echo "2. Checking for active hardcoded resolutions..."
ACTIVE_RES=$(grep -rn "1920x1200\|2560x1440" hypr/ --include="*.conf" 2>/dev/null | grep -v "#" | grep -v "commented" | wc -l)
if [[ "$ACTIVE_RES" -eq 0 ]]; then
    echo "   ✅ PASS: No active resolution hardcodes"
else
    echo "   ❌ FAIL: Found $ACTIVE_RES active resolution hardcodes"
    FAILED=$((FAILED + 1))
fi

# 3. Check script syntax
echo "3. Checking pkgtrack.sh syntax..."
if bash -n scripts/pkgtrack.sh 2>/dev/null; then
    echo "   ✅ PASS: pkgtrack.sh syntax valid"
else
    echo "   ❌ FAIL: pkgtrack.sh has syntax errors"
    FAILED=$((FAILED + 1))
fi

# 4. Check pacman hook exists
echo "4. Checking pacman hook configuration..."
if [[ -f pacman-hook-autotrack.hook ]]; then
    if grep -q "Operation = Remove" pacman-hook-autotrack.hook; then
        echo "   ✅ PASS: Hook includes Remove operation"
    else
        echo "   ❌ FAIL: Hook missing Remove operation"
        FAILED=$((FAILED + 1))
    fi
else
    echo "   ❌ FAIL: pacman-hook-autotrack.hook not found"
    FAILED=$((FAILED + 1))
fi

# 5. Check for duplicate scripts (cleanup verification)
echo "5. Checking for old duplicate scripts..."
DUPLICATES=$(ls scripts/pkgtrack_*.sh 2>/dev/null | wc -l)
if [[ "$DUPLICATES" -le 1 ]]; then
    echo "   ✅ PASS: No duplicate pkgtrack scripts"
else
    echo "   ❌ FAIL: Found $DUPLICATES pkgtrack scripts (should be 1)"
    FAILED=$((FAILED + 1))
fi

# 6. Check config.sh exists
echo "6. Checking config.sh exists..."
if [[ -f scripts/config.sh ]]; then
    echo "   ✅ PASS: config.sh exists"
else
    echo "   ❌ FAIL: config.sh not found"
    FAILED=$((FAILED + 1))
fi

# 7. Check architecture is clean
echo "7. Checking script architecture..."
SCRIPT_COUNT=$(ls scripts/*.sh 2>/dev/null | wc -l)
if [[ "$SCRIPT_COUNT" -le 5 ]]; then
    echo "   ✅ PASS: Clean architecture ($SCRIPT_COUNT scripts)"
else
    echo "   ⚠️  WARN: Many scripts ($SCRIPT_COUNT) - may need cleanup"
fi

# Final verdict
echo ""
echo "=== VERIFICATION RESULT ==="
if [[ "$FAILED" -eq 0 ]]; then
    echo "✅ ALL CHECKS PASSED - PRODUCTION READY"
    exit 0
else
    echo "❌ $FAILED CRITICAL ISSUES FOUND - NOT PRODUCTION READY"
    exit 1
fi
