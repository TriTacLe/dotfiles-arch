# Arch Linux Dotfiles

dotfiles for Arch Linux

# Credits

Created by [filiprs](https://github.com/filiprs)

## Quick Start

```bash
# Clone and setup
cd ~
git clone https://github.com/TriTacLe/dotfiles-arch.git dotfiles
cd dotfiles

# Setup your credentials (machine-specific settings)
cp .env.example .env
nvim .env  # Add your name, email, monitors, etc.

# Run installation
./install.sh
```

The installer automatically:

- Installs all required packages
- Stows your configuration files
- Reloads running applications (Hyprland, waybar, kitty, etc.)
- Applies zsh changes if running in zsh

No reboot required for most changes!

## What Gets Installed

- packages (all organized in one file)
- Hyprland config (window manager)
- Shell setup (zsh, starship)
- Development tools (neovim, tmux, git)
- Terminal tools (fzf, eza, bat, jq)

## Package Tracking

The system automatically tracks all package installations:

```bash
# Pacman automatically runs tracking after each install
sudo pacman -S new-package

# Verify it worked
git log --oneline -3
```

## Test

Run the verification script:

```bash
./verify-system.sh
```

This checks safety critical systems before production deployment.
