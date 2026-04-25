# Dotfiles

Personal Arch Linux dotfiles managed with GNU Stow.

Credits: [@filip-rs](https://github.com/filip-rs)

## Install

```bash
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

That's it! Everything sets up automatically including package tracking.

## Quick Commands

```bash
./scripts/verify.sh           # Test everything works
./scripts/pkgtrack.sh list    # See all tracked packages
./install.sh --packages       # Update packages only
./install.sh --stow           # Update configs only
```

## Usage

```bash
make install    # Full install
make stow       # Stow all configs
make unstow     # Remove stowed configs
make list       # List stowed configs
make test       # Run tests
./install.sh --packages   # Packages only
./install.sh --stow       # Stow only
```

## Structure

Each directory is a stow package:
- `packages/*.txt` - All 209 organized packages
- `scripts/` - Automation tools and verification
- `hypr/`, `nvim/`, `terminal/` - Config files
- `install.sh` - Full automated setup

## Special Features

- **Auto-tracking**: Install any package → auto-tracked → auto-committed → auto-pushed
- **Perfect sync**: All PCs stay identical automatically
- **Keyboard**: Print Screen types `~`, special character shortcuts
- **Conflict-free**: Safe to run install.sh multiple times
- **Self-healing**: Verification system detects and fixes issues

## Configuration

Copy `.env.example` to `.env` and add your values:

```bash
cp .env.example .env
```

Run `./install.sh` to apply.

## What's NOT Included

These are intentionally excluded from the repo:

- **SSH config** - Personal host info
- **Secrets** - API keys in `.env` (copy from `.env.example`)
- **Git user** - Set via `GIT_USER_NAME` and `GIT_USER_EMAIL` in `.env`
- **Generated files** - Like `.zcompdump` (auto-created)

## Features

### Automatic Package Tracking
Every package install gets automatically tracked and synced across all PCs with structured Git commits.

### Quick Verification
Run `./scripts/verify.sh` to test everything works (15 automated tests).

### Perfect Synchronization
Flawless sync between PCs with auto-commit and auto-push to GitHub.

### Safe Updates
Install script is idempotent - run it multiple times safely without conflicts.
