# Dotfiles

Personlige dotfiles for Arch Linux system, optimalisert for Hyprland og moderne utviklingsverktøy.

**Mega creds til:** @filip-rs for inspirasjon og co-authored commits!

## Systemoversikt

Dette repoet inneholder konfigurasjonsfiler for:
- **Window Manager**: Hyprland (Wayland compositor)
- **Shell**: Zsh med Oh-My-Zsh og Powerlevel10k
- **Editor**: Neovim (LazyVim distribusjon)
- **Terminal**: Ghostty & Kitty
- **Multiplexer**: Tmux
- **Tema**: Catppuccin Mocha

## Installasjon

### 1. Pakker
```bash
# Installere alle pakker fra pacman.txt
sudo pacman -S --needed - < pacman.txt

# Eller installere AUR-hjelper (yay/paru) først
yay -S --needed - < pacman.txt
```

### 2. Dotfiles (med GNU Stow)
```bash
cd ~/dotfiles
stow . --dotfiles -t ~
```

## Struktur

```
configs/
├── alacritty/      # Terminal emulator konfig
├── fastfetch/      # System info display
├── ghostty/        # Terminal emulator (primær)
├── git/            # Git konfigurasjon
├── hypr/           # Hyprland window manager
├── kitty/          # Terminal emulator (sekundær)
├── lazygit/        # Git TUI
├── nvim/           # Neovim konfigurasjon
├── starship/       # Prompt
├── swaync/         # Notifikasjoner
├── tmux/           # Terminal multiplexer
├── waybar/         # Status bar
├── wofi/           # Application launcher
├── zathura/        # PDF viewer
└── zsh/            # Shell konfigurasjon
```

## Viktige snarveier

### Hyprland
- `Super + Enter` - Åpne terminal
- `Super + Q` - Lukk vindu
- `Super + M` - Avslutt Hyprland
- `Super + R` - Åpne Wofi (launcher)
- `Super + [1-9]` - Bytt workspace

### Tmux
- `Ctrl + A` - Prefix
- `Prefix + c` - Nytt vindu
- `Prefix + n/p` - Neste/forrige vindu
- `Prefix + %` - Splitt vertikalt
- `Prefix + "` - Splitt horisontalt

### Neovim
- `<Space>` - Leader key
- `<Space>e` - File explorer
- `<Space>ff` - Find files
- `<Space>fg` - Live grep

## Tilpasninger

### Per-maskin konfigurasjon
Zsh-konfigurasjonen støtter maskin-spesifikke tilpasninger via `case "$HOST"` i `.zshrc`.

### Tilgjengelige aliaser
- `update` - Systemoppdatering (pacman/apt basert på system)
- `gacp "melding"` - Git add, commit, push
- `lss` - Tree view med ikoner (nivå 2)
- `dotfiles` - cd til dotfiles mappe

## Vedlikehold

### Oppdatere pacman.txt
```bash
pacman -Qqe > pacman.txt
```

### Sikkerhet
- Ingen API-nøkler eller passord i repoet
- Personlige data i `.gitignore`
- Bruk `~/.zshrc.local` for maskin-spesifikke hemmeligheter

## Co-authored commits

For å co-autore commits med andre:
```bash
git commit -m "Feature X

Co-authored-by: Navn <bruker@users.noreply.github.com>"
```

## Lisens

MIT License - Se LICENSE fil for detaljer.

---

**Sist oppdatert**: 2026-03-18  
**Forfatter**: Tri Tac Le  
**Co-author**: Filip R. Spanne (@filip-rs)
