#!/bin/bash
# Setup script for auto-tracking on each PC
echo "Setting up automatic package tracking..."

# Install pacman hook
echo "Installing pacman hook..."
sudo cp pacman-hook-autotrack.hook /usr/share/libalpm/hooks/20-dotfiles-autotrack.hook

# Copy tracking script
echo "Copying tracking script..."
mkdir -p ~/.config/hypr/scripts
cp scripts/pkgtrack_auto.sh ~/.config/hypr/scripts/

echo "✅ Auto-tracking setup complete!"
echo ""
echo "─ HOW IT WORKS NOW ──"
echo ""
echo "1) Install packages (automatic tracking):"
echo "   sudo pacman -S package-name"
echo "   yay -S aur-package"
echo ""
echo "2) 🤖 AUTOMATIC:"
echo "   ✓ Packages added to packages/*.txt"
echo "   ✓ Git commit: '[AUTO] 🤖 Tracked packages: package-name'"
echo "   ✓ Auto-push to GitHub 🚀"
echo ""
echo "3) Pull on other PC:"
echo "   git pull"
echo "   ./install.sh --packages"
echo ""
echo "─ COMMIT MESSAGE FORMAT ──"
echo ""
echo "Structure: '[AUTO] 🤖 Tracked packages: pkg1 pkg2'"
echo ""
echo "Benefits:"
echo "• Clearly shows it's an automatic commit"
echo "• Includes bot emoji for easy identification"
echo "• Lists all packages in the message"
echo "• Timestamp in git history"
echo ""
echo "⚠  This setup is PER-PC - run this script on each machine!"
echo ""
echo "─ GITHUB AUTHENTICATION ──"
echo ""
echo "Auto-push requires GitHub authentication:"
echo "• SSH keys: git@github.com:..."
echo "• Or token auth: https://github.com/..."
echo ""
echo "If push fails:"
echo "• Check GitHub SSH keys"
echo "• Or disable auto-push in pkgtrack_auto.sh"