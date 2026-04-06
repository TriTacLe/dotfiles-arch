# Arch Linux Dotfiles

A modular, stow-managed dotfiles configuration for Arch Linux with Hyprland.

**Huge Credits:** [@filip-rs](https://github.com/filip-rs)

![Screenshot](screenshot.png)

## Features

- **Modular Design** - Each component is a separate stow package
- **One-Command Install** - Get up and running with a single command
- **Hyprland Desktop** - Modern Wayland compositor with custom theming
- **Zsh + Powerlevel10k** - Fast, feature-rich shell with instant prompt
- **Neovim (LazyVim)** - IDE-like text editor with LSP support
- **Modern Terminal** - Ghostty/Alacritty with Catppuccin theme
- **Tmux** - Terminal multiplexer with sensible defaults

## Quick Start

### Fresh Arch Install

```bash
# 1. Clone the repository
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles

# 2. Run the installer
./install.sh

# 3. Reboot and enjoy!
sudo reboot
```

That's it! The installer will:
- Install all necessary packages
- Set up AUR helper (yay)
- Create symlinks with stow
- Configure services (NetworkManager, Bluetooth, SDDM)
- Set zsh as default shell

### Using Make

```bash
# Full installation
make install

# Install packages only
make install-packages

# Stow dotfiles only
make install-stow

# Update dotfiles
make update

# List available packages
make list

# Stow specific package
make stow PACKAGE=nvim
```

## Structure

```
dotfiles/
├── alacritty/         # Terminal emulator (fallback)
├── fastfetch/         # System info display
├── ghostty/           # Primary terminal emulator
├── git/               # Git configuration
├── hypr/              # Hyprland WM config
├── kitty/             # Terminal emulator (alternative)
├── misc/              # Miscellaneous configs
├── nvim/              # Neovim configuration (LazyVim)
├── starship/          # Shell prompt
├── tmux/              # Terminal multiplexer
├── waybar/            # Status bar
├── wofi/              # Application launcher
├── zsh/               # Zsh shell config
├── packages/          # Package lists
│   ├── core.txt       # Essential system packages
│   ├── terminal.txt   # Shell and terminal
│   ├── development.txt# Dev tools
│   ├── desktop.txt    # Hyprland and DE
│   ├── applications.txt# GUI apps
│   └── aur.txt        # AUR packages
├── bin/               # Custom scripts
├── install.sh         # Main installation script
└── Makefile           # Convenient commands
```

## Package Groups

### Core (`packages/core.txt`)
Essential system packages including kernel, firmware, networking, and base utilities.

### Terminal (`packages/terminal.txt`)
- Shell: zsh, oh-my-zsh, powerlevel10k
- Terminals: ghostty, kitty, alacritty
- Tools: fzf, zoxide, eza, bat, btop

### Development (`packages/development.txt`)
- Editors: neovim, vim
- Tools: git, lazygit, tmux, docker
- Languages: nodejs, npm, python

### Desktop (`packages/desktop.txt`)
- WM: hyprland, hyprpaper, hyprlock, hypridle
- Launcher: wofi
- Bar: waybar
- Notifications: swaync
- Theme: catppuccin-gtk-theme-mocha

### Applications (`packages/applications.txt`)
- Browsers: firefox, firefox-developer-edition, brave
- Apps: obsidian, spotify, slack, vscode
- Utils: gnome-calculator, gnome-calendar, libreoffice

## Manual Stow

If you prefer manual control:

```bash
# Stow all packages
stow */ --dotfiles -t ~

# Stow specific package
stow zsh --dotfiles -t ~
stow nvim --dotfiles -t ~

# Unstow package
stow -D zsh --dotfiles -t ~

# Re-stow (adopt existing files)
stow --adopt zsh --dotfiles -t ~
```

## Post-Installation

### 1. Tmux Plugins

Open tmux and press `Ctrl+Space + I` to install plugins.

### 2. Neovim

First launch will automatically download and install LazyVim plugins.

### 3. Zsh Theme

Run `p10k configure` to customize the Powerlevel10k prompt.

### 4. Hyprland

Logout and select Hyprland from SDDM (or run `Hyprland` from TTY).

## Keybindings

### Hyprland

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal |
| `Super + Q` | Close window |
| `Super + M` | Exit Hyprland |
| `Super + E` | Open file manager |
| `Super + V` | Toggle floating |
| `Super + R` | Open launcher (wofi) |
| `Super + P` | Pseudo tile window |
| `Super + J` | Toggle split |
| `Super + [1-9]` | Switch workspace |
| `Super + Shift + [1-9]` | Move to workspace |
| `Super + Arrow` | Change focus |
| `Super + Shift + Arrow` | Resize window |
| `Super + Mouse` | Drag/resize window |
| `Print` | Screenshot |

### Neovim

See [GUIDE.md](GUIDE.md) for detailed Neovim keybindings.

### Tmux

| Key | Action |
|-----|--------|
| `Ctrl+Space` | Prefix key |
| `Prefix + h/j/k/l` | Navigate panes |
| `Prefix + H/L` | Previous/next window |
| `Prefix + r` | Reload config |
| `Prefix + Shift+h/j/k/l` | Resize pane |

## Customization

### Adding New Configs

1. Create a new directory: `mkdir mypackage`
2. Add your config files following the stow structure
3. Stow it: `stow mypackage --dotfiles -t ~`

Example structure:
```
mypackage/
└── .config/
    └── myapp/
        └── config.conf
```

### Adding Packages

Edit the appropriate file in `packages/`:
- `core.txt` - System packages
- `terminal.txt` - Terminal tools
- `development.txt` - Dev tools
- `desktop.txt` - Desktop environment
- `applications.txt` - GUI apps
- `aur.txt` - AUR packages

Then run: `make install-packages`

## Troubleshooting

### Stow Conflicts

If stow reports conflicts:

```bash
# Adopt existing files (backup first!)
stow --adopt <package> --dotfiles -t ~

# Or backup and remove conflicting files
mv ~/.config/<package> ~/.config/<package>.backup
stow <package> --dotfiles -t ~
```

### Permission Issues

Some operations require sudo. The install script will prompt when needed.

### Display Issues

If Hyprland doesn't start:
- Check GPU drivers are installed
- For NVIDIA: additional configuration may be needed
- Check `~/.local/share/hyprland/hyprland.log`

### Neovim Issues

```bash
# Reset Neovim completely
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# Re-stow
cd ~/dotfiles && stow nvim --dotfiles -t ~
```

## Maintenance

### Update Dotfiles

```bash
cd ~/dotfiles
git pull
make update
```

### Update Packages

```bash
# Official packages
sudo pacman -Syu

# AUR packages
yay -Syu
```

### Backup Current Config

```bash
make backup
```

## Requirements

- Arch Linux (or Arch-based distro)
- Internet connection
- sudo access
- Git

## Credits

- **[@filip-rs](https://github.com/filip-rs)** - Original configuration inspiration
- **Hyprland** - [hyprland.org](https://hyprland.org/)
- **LazyVim** - [lazyvim.github.io](https://www.lazyvim.org/)
- **Catppuccin** - [catppuccin.com](https://catppuccin.com/)
- **Oh My Zsh** - [ohmyz.sh](https://ohmyz.sh/)

## License

MIT License - Feel free to use and modify!

---

**Pro tip:** After installation, run `fetch` or `fastfetch` to see your new system info display!
