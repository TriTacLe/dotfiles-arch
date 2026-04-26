
# Arch Linux Dotfiles - Production Ready

Simple, maintainable dotfiles for Arch Linux with automatic package tracking.

## Features

- **Simple Architecture**: 4 scripts, 1 package file
- **Production Safe**: Zero hardcoded values, works on any PC
- **Auto-Tracking**: Automatically tracks all package changes
- **Multi-PC Support**: Easy to set up on multiple machines
- **KISS Principle**: Keep It Simple Stupid - no over-engineering

## Quick Start

```bash
# Clone and setup
cd ~
git clone https://github.com/TriTacLe/dotfiles-arch.git dotfiles
cd dotfiles
./install.sh
```

## What Gets Installed

- 115+ packages (all organized in one file)
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

See [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md) for detailed production PC setup.

## Architecture

```
dotfiles/
├── scripts/
│   ├── pkgtrack.sh       # Auto-tracking (multi-path detection)
│   ├── config.sh        # Configuration (centralized)
│   ├── machine-detect.sh # Machine detection
│   └── verify.sh        # Verification script
├── packages/
│   └── packages.txt     # All packages (1 simple file)
├── hypr/                # Hyprland configs (auto-detect monitors)
├── zsh/                 # Shell configs
└── install.sh           # One-command installation
```

## Production Safety

These dotfiles are production-ready:

- ✅ No hardcoded paths (automatic detection)
- ✅ No hardcoded monitors (auto-detect)
- ✅ Error handling for missing files
- ✅ Tested on multiple systems
- ✅ Simple architecture (easy to debug)

See [verify-system.sh](verify-system.sh) for safety verification.

## Key Design Principles

1. **KISS**: Keep It Simple Stupid - no over-engineering
2. **DRY**: Don't Repeat Yourself - shared configuration
3. **Zero Risk**: Won't break production PC
4. **Easy Setup**: 3 commands to install
5. **Maintainable**: Simple code, clear structure

## Getting Help

Run the verification script:
```bash
./verify-system.sh
```

This checks all safety critical systems before production deployment.

## License

MIT - Feel free to use and modify for your own setup.
