# Dotfiles User Guide

Complete guide for using and maintaining these dotfiles.

## Table of Contents

1. [Installation](#installation)
2. [Structure](#structure)
3. [Managing Dotfiles](#managing-dotfiles)
4. [Package Management](#package-management)
5. [Troubleshooting](#troubleshooting)
6. [Customization](#customization)

---

## Installation

### Fresh Install (Recommended)

```bash
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Using Make

```bash
make install          # Full installation
make install-packages # Packages only
make install-stow     # Stow only
```

### Manual Installation

```bash
# Install packages manually
sudo pacman -S - < packages/core.txt
sudo pacman -S - < packages/terminal.txt
# ... etc

# Stow packages manually
stow zsh nvim tmux git hypr waybar --dotfiles -t ~
```

---

## Structure

```
dotfiles/
├── zsh/              # Shell configuration
│   ├── .zshrc       # Main zsh config
│   └── .config/zsh/ # Additional zsh configs
├── nvim/            # Neovim (LazyVim)
├── tmux/            # Terminal multiplexer
├── git/             # Git configuration
├── hypr/            # Hyprland WM
├── waybar/          # Status bar
├── ghostty/         # Terminal emulator
├── kitty/           # Alternative terminal
├── alacritty/       # Fallback terminal
├── fastfetch/       # System info
├── wofi/            # App launcher
├── starship/        # Shell prompt
├── misc/            # Other configs
├── packages/        # Package lists
│   ├── core.txt
│   ├── terminal.txt
│   ├── development.txt
│   ├── desktop.txt
│   ├── applications.txt
│   └── aur.txt
├── scripts/         # Helper scripts
├── install.sh       # Main installer
└── Makefile         # Convenient commands
```

---

## Managing Dotfiles

### Stow Commands

Stow creates symlinks from your home directory to the dotfiles repo.

```bash
# Stow all packages
stow */ --dotfiles -t ~

# Stow specific package
stow zsh --dotfiles -t ~

# Unstow (remove symlinks)
stow -D zsh --dotfiles -t ~

# Re-stow (refresh)
stow -R zsh --dotfiles -t ~

# Adopt existing files
stow --adopt zsh --dotfiles -t ~
```

### Make Commands

```bash
make list            # List all packages and status
make stow            # Stow all packages
make stow PACKAGE=zsh # Stow specific package
make unstow          # Unstow all
make reinstall       # Unstow + stow
make update          # Update dotfiles
make backup          # Backup current configs
make clean           # Clean backup files
make check           # Check installation status
```

---

## Package Management

### Package Groups

| File | Purpose |
|------|---------|
| `packages/core.txt` | Essential system packages |
| `packages/terminal.txt` | Shell, terminals, CLI tools |
| `packages/development.txt` | Dev tools, editors, languages |
| `packages/desktop.txt` | Hyprland, wayland, theming |
| `packages/applications.txt` | GUI applications |
| `packages/aur.txt` | AUR-only packages |

### Installing Packages

```bash
# Install from a specific file
sudo pacman -S --needed - < packages/terminal.txt

# Install AUR packages
yay -S --needed - < packages/aur.txt

# Or use the install script
./install.sh --packages
```

### Adding New Packages

1. Edit the appropriate `packages/*.txt` file
2. Add package names (one per line)
3. Run `make install-packages`

---

## Component Guides

### Zsh

**Key Features:**
- Oh-My-Zsh framework
- Powerlevel10k theme (instant prompt)
- zsh-autosuggestions
- zsh-syntax-highlighting
- zoxide (smart cd)
- fzf integration

**Important Aliases:**

| Alias | Command |
|-------|---------|
| `cat` | `bat --paging=never` |
| `ls` | `eza --icons` |
| `la` | `eza -la --icons --git` |
| `ll` | `eza --tree --icons --level=2` |
| `..` | `cd ..` |
| `z` | `zoxide` (fuzzy cd) |

**Customize:**
```bash
p10k configure    # Customize prompt
zshconf           # Edit .zshrc
```

### Neovim (LazyVim)

**Leader Key:** `Space`

**Essential Keymaps:**

| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file explorer |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep (search in files) |
| `<Space>fb` | List buffers |
| `<Space>bd` | Close buffer |
| `gd` | Go to definition |
| `K` | Show documentation |
| `<Space>ca` | Code action |
| `<Space>rn` | Rename symbol |

**LSP Management:**
```vim
:Mason          # Install language servers
:LspInfo        # Check LSP status
:Lazy           # Plugin manager
:checkhealth    # Health check
```

**Plugin Structure:**
```
nvim/.config/nvim/lua/plugins/
├── lang/          # Language-specific
│   ├── java.lua
│   ├── go.lua
│   └── frontend.lua
└── tools/         # Tools and utilities
    ├── dap.lua
    └── auto-save.lua
```

### Tmux

**Prefix:** `Ctrl+Space`

**Keybindings:**

| Key | Action |
|-----|--------|
| `Prefix + h/j/k/l` | Navigate panes |
| `Prefix + H/L` | Previous/next window |
| `Prefix + c` | Create window |
| `Prefix + n` | New window (named) |
| `Prefix + &` | Kill window |
| `Prefix + %` | Split vertical |
| `Prefix + "` | Split horizontal |
| `Prefix + r` | Reload config |
| `Prefix + I` | Install plugins (TPM) |

**Plugins:**
- tmux-sensible (sensible defaults)
- tmux-resurrect (save/restore sessions)
- tmux-continuum (auto-save)
- minimal-tmux-status (theme)

### Hyprland

**Modifier:** `SUPER` (Windows key)

**Window Management:**

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal |
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo tile |
| `Super + J` | Toggle split |
| `Super + click` | Drag window |
| `Super + RClick` | Resize window |

**Workspaces:**

| Key | Action |
|-----|--------|
| `Super + [1-9]` | Switch to workspace |
| `Super + Shift + [1-9]` | Move to workspace |
| `Super + Scroll` | Switch workspace |

**Launchers:**

| Key | Action |
|-----|--------|
| `Super + R` | Application launcher (wofi) |
| `Super + E` | File manager |
| `Print` | Screenshot (hyprshot) |

**Configuration Files:**
```
hypr/.config/hypr/
├── hyprland.conf      # Main config
├── hyprpaper.conf     # Wallpaper
└── scripts/           # Helper scripts
```

---

## Troubleshooting

### Stow Conflicts

**Problem:** Stow reports conflicts with existing files

**Solution 1 - Backup and replace:**
```bash
mv ~/.config/nvim ~/.config/nvim.backup
stow nvim --dotfiles -t ~
```

**Solution 2 - Adopt files:**
```bash
stow --adopt nvim --dotfiles -t ~
git diff  # Review changes
```

### Neovim Issues

**Plugins not loading:**
```bash
rm -rf ~/.local/share/nvim/lazy
rm ~/.config/nvim/lazy-lock.json
nvim  # Will reinstall plugins
```

**LSP not working:**
```vim
:Mason  # Ensure LSP is installed
:LspInfo  # Check status
```

### Zsh Slow Startup

**Profile startup:**
```bash
zmodload zsh/zprof
# ... restart shell ...
zprof
```

**Common causes:**
- Too many plugins
- Slow nvm initialization (use lazy loading)
- Large completion dumps

### Hyprland Won't Start

**Check logs:**
```bash
cat ~/.local/share/hyprland/hyprland.log
```

**Common fixes:**
- Install GPU drivers
- For NVIDIA: install `nvidia` and `nvidia-utils`
- Check permissions: user must be in `video` group

---

## Customization

### Adding a New Stow Package

1. Create directory structure:
```bash
mkdir -p myapp/.config/myapp
cp ~/.config/myapp/config.conf myapp/.config/myapp/
```

2. Stow it:
```bash
stow myapp --dotfiles -t ~
```

3. Commit:
```bash
git add myapp
git commit -m "Add myapp config"
```

### Creating Custom Scripts

Add scripts to `bin/` directory:

```bash
# dotfiles/bin/myscript
#!/bin/bash
echo "Hello from my script!"
```

Make executable:
```bash
chmod +x dotfiles/bin/myscript
```

The install script adds `~/bin` to your PATH.

### Modifying Package Lists

Edit files in `packages/`:

```bash
# packages/custom.txt
my-custom-package
another-package
```

Install:
```bash
sudo pacman -S --needed - < packages/custom.txt
```

---

## Maintenance

### Regular Updates

```bash
# Update system
sudo pacman -Syu
yay -Sua

# Update dotfiles
cd ~/dotfiles
git pull
make update
```

### Backup

```bash
make backup
# Creates: ~/.dotfiles-backup/YYYYMMDD-HHMMSS.tar.gz
```

### Clean Up

```bash
make clean  # Remove backup files
```

---

## Tips

1. **Use `z` instead of `cd`** - zoxide learns your habits
2. **Ctrl+T** in terminal - fzf file finder
3. **Ctrl+R** in terminal - fzf history search
4. **tmux resurrect** - Save sessions with `Prefix + Ctrl+s`, restore with `Prefix + Ctrl+r`
5. **LazyVim** - Check `:Lazy` for plugin updates
6. **stow adopt** - Use when you have existing configs to merge

---

## Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [LazyVim Docs](https://www.lazyvim.org/)
- [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Catppuccin Theme](https://catppuccin.com/)
