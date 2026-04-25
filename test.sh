#!/bin/bash

echo "Running tests..."
fail=0

bash -n install.sh || { echo "FAIL: install.sh syntax"; fail=1; }

if ! grep -q '\.git' .stow-local-ignore; then
    echo "FAIL: .stow-local-ignore missing .git"
    fail=1
fi

if grep -rn '/home/tri' --include="*.conf" --include="*.service" . 2>/dev/null | grep -v test.sh | grep -q .; then
    echo "FAIL: hardcoded paths found"
    fail=1
fi

if [[ $fail -eq 0 ]]; then
    echo "All tests passed"
    exit 0
else
    exit 1
fi
