#!/bin/bash
# Install pac man hook system-wide for ANY PC setup

# Create system-wide symlink (requires sudo)
sudo ln -sf /home/tri/Desktop/dotfiles/scripts/pkgtrack.sh /usr/local/bin/dotfiles-pkgtrack
sudo chmod +x /usr/local/bin/dotfiles-pkgtrack

echo "✅ System-wide hook installed"
echo "   Script available at: /usr/local/bin/dotfiles-pkgtrack"
echo ""
echo "Now update the hook file to use this new location."
