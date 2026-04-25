# Dotfiles Installation Guide

## New PC Setup (3 Commands)

```bash
git clone https://github.com/TriTacLe/dotfiles-arch.git ~/Desktop/dotfiles
cd ~/Desktop/dotfiles
./install.sh
```

**That's it!** ✅

## What Install Script Does Automatically

1. ✓ Updates system packages
2. ✓ Installs yay (AUR helper)
3. ✓ Installs all 209 packages from `packages/*.txt`
4. ✓ Stows all config files (zsh, neovim, hyprland, etc.)
5. ✓ Sets up zsh as default shell
6. ✓ Enables services (ssh-agent, etc.)
7. ✓ **Sets up automatic package tracking** 🤖
8. ✓ Installs pacman hook for package tracking
9. ✓ ✨ Everything works!

## After Installation

### Test Everything Works
```bash
./scripts/verify.sh
```

Expected output:
```
Passed: 14/14 tests
✓ ALL TESTS PASSED!
```

### Test Package Tracking
```bash
sudo pacman -S tree  # Install a test package
```

Automatic results:
- ✓ Package added to `packages/terminal.txt`
- ✓ Git commit: `[AUTO] 🤖 Tracked packages: tree`
- ✓ Auto-pushed to GitHub 🚀

## Daily Usage

### Installing Packages
```bash
sudo pacman -S package-name
yay -S aur-package
```

**Everything automatic:**
- ✓ Package tracked in dotfiles
- ✓ Git commit created
- ✓ Pushed to GitHub

### Testing & Verification
```bash
cd ~/Desktop/dotfiles
./scripts/verify.sh  # Run verification anytime
```

### Manual Package Review
```bash
./scripts/pkgtrack.sh list   # See all tracked packages
./scripts/pkgtrack.sh diff   # See new/untracked packages
```

## Syncing Between PCs

### Updating Current PC
```bash
cd ~/Desktop/dotfiles
git pull
./install.sh --packages  # Install any new packages
```

### Setting Up New PC
```bash
git clone https://github.com/TriTacLe/dotfiles-arch.git ~/Desktop/dotfiles
cd ~/Desktop/dotfiles
./install.sh  # DONE!
```

## Troubleshooting

### Auto-tracking Not Working
```bash
cd ~/Desktop/dotfiles
./scripts/setup-autotrack.sh  # Re-run setup
```

### Packages Not Installing
```bash
# Verify package files exist
ls packages/*.txt

# Try installing manually
./install.sh --packages
```

### Git Push Failing
```bash
# Check GitHub authentication
git push origin master

# If SSH not configured:
git remote set-url origin https://github.com/TriTacLe/dotfiles-arch.git
```

## Git History

### See Automatic Commits
```bash
git log --grep='\[AUTO\]'  # Only show auto-commits
```

### See Manual Commits
```bash
git log --grep -v '\[AUTO\]'  # Only show manual commits
```

### All Commits
```bash
git log --oneline
```

## Features

### What's Automatic
- ✅ Package tracking
- ✅ Git commits (structured: `[AUTO] 🤖 Tracked packages: pkg1 pkg2`)
- ✅ GitHub push 🚀
- ✅ Package categorization
- ✅ Duplicate prevention
- ✅ Config stowing
- ✅ Shell setup

### What's Manual
- ⏸️ git push (only if auto-push fails)
- ⏸️ Package removal from lists (if you don't want something)
- ⏸️ Config modifications (when you want to customize)

## System Requirements

- Arch Linux (or Arch-based)
- Internet connection
- Sudo access
- ~3GB disk space for packages
- ~10 minutes for setup time

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./install.sh` | Full installation (everything) |
| `./install.sh --packages` | Install packages only |
| `./install.sh --stow` | Stow configs only |
| `./scripts/verify.sh` | Test everything works |
| `./scripts/pkgtrack.sh list` | See tracked packages |
| `./scripts/setup-autotrack.sh` | Setup auto-tracking |

## Support

If something fails:
1. Run `./scripts/verify.sh`
2. Check the error message
3. Try the relevant command manually
4. Check git history for recent changes

**Your dotfiles are production-ready!** 🚀