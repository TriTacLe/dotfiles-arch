# Installation Guide

This guide covers installing these dotfiles on a fresh Arch Linux system.

## Prerequisites

- Arch Linux (or Arch-based distro like EndeavourOS, Manjaro)
- Internet connection
- sudo access
- Git installed

## Quick Install

```bash
# 1. Install git if not already installed
sudo pacman -S git

# 2. Clone the repository
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles

# 3. Run the installer
./install.sh

# 4. Reboot
sudo reboot
```

That's it! The installer will:
- Check your system
- Install yay (AUR helper)
- Install all packages
- Stow all dotfiles
- Set up services
- Configure the shell

## Step-by-Step Installation

### 1. Base Arch Installation

If you're starting from scratch, install Arch Linux following the [Arch Wiki Installation Guide](https://wiki.archlinux.org/title/Installation_guide).

Minimum recommended:
- 50GB disk space
- 4GB RAM
- Internet connection

### 2. Clone Repository

```bash
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles
```

### 3. Run Installer

The install script has several modes:

**Full installation (recommended):**
```bash
./install.sh
```

**Install packages only:**
```bash
./install.sh --packages
```

**Stow dotfiles only:**
```bash
./install.sh --stow
```

**Or use Make:**
```bash
make install          # Full install
make install-packages # Packages only
make install-stow     # Stow only
```

### 4. Post-Installation

After the installer finishes:

1. **Reboot** your system
2. **Login** to SDDM and select Hyprland
3. **Open a terminal** (Super + Enter)
4. **Setup tmux plugins**: Open tmux, press `Ctrl+Space + I`
5. **Setup Neovim**: Run `nvim`, wait for plugins to install
6. **Configure zsh theme** (optional): Run `p10k configure`

## Manual Installation

If you prefer to install manually:

### Install Packages

```bash
# Install yay first
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Install packages
sudo pacman -S --needed - < packages/core.txt
sudo pacman -S --needed - < packages/terminal.txt
sudo pacman -S --needed - < packages/development.txt
sudo pacman -S --needed - < packages/desktop.txt
sudo pacman -S --needed - < packages/applications.txt
yay -S --needed - < packages/aur.txt
```

### Stow Dotfiles

```bash
cd ~/dotfiles

# Stow all packages
stow alacritty fastfetch ghostty git hypr kitty \
     misc nvim starship tmux waybar wofi zsh \
     --dotfiles -t ~
```

### Post-Install Setup

```bash
# Change shell to zsh
chsh -s /bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Enable services
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm
sudo systemctl enable docker
```

## What Gets Installed

### Desktop Environment
- **Hyprland** - Wayland compositor
- **Waybar** - Status bar
- **Wofi** - Application launcher
- **SwayNC** - Notifications
- **SDDM** - Display manager

### Terminal & Shell
- **Zsh** - Shell with oh-my-zsh
- **Powerlevel10k** - Fast prompt theme
- **Ghostty** - Primary terminal
- **Kitty/Alacritty** - Alternative terminals
- **Tmux** - Terminal multiplexer

### Development
- **Neovim** - Text editor (LazyVim)
- **Git** - Version control
- **Docker** - Containerization
- **Node.js/Python** - Languages

### Applications
- **Firefox** - Browser
- **Obsidian** - Notes
- **Spotify** - Music
- **LibreOffice** - Office suite

### CLI Tools
- **fzf** - Fuzzy finder
- **zoxide** - Smart cd
- **eza** - Modern ls
- **bat** - Syntax highlighting cat
- **btop** - System monitor

## Troubleshooting

### Stow Conflicts

If you see "conflicts" errors:

```bash
# Option 1: Backup and replace
mv ~/.config/nvim ~/.config/nvim.backup
stow nvim --dotfiles -t ~

# Option 2: Adopt existing files
stow --adopt nvim --dotfiles -t ~
```

### Package Installation Fails

```bash
# Update package database first
sudo pacman -Syy

# Try installing individually to see which fails
sudo pacman -S package-name
```

### Hyprland Won't Start

1. Check you're in the `video` group: `groups`
2. Check GPU drivers are installed
3. Check logs: `cat ~/.local/share/hyprland/hyprland.log`

### Neovim Won't Start

```bash
# Reset neovim completely
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
cd ~/dotfiles
stow nvim --dotfiles -t ~
nvim
```

## Verification

Check installation status:

```bash
make check
# or
./scripts/check.sh
```

## Next Steps

- Read [GUIDE.md](GUIDE.md) for detailed usage instructions
- Customize configs in `~/dotfiles/`
- Add your own packages to `packages/`
- Run `make backup` before making big changes

## Support

If you encounter issues:

1. Check [GUIDE.md](GUIDE.md) troubleshooting section
2. Review the [Arch Wiki](https://wiki.archlinux.org/)
3. Check component documentation:
   - [Hyprland Wiki](https://wiki.hyprland.org/)
   - [LazyVim Docs](https://www.lazyvim.org/)
