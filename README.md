# Dotfiles

Personal Arch Linux dotfiles managed with GNU Stow.

Massive Credits: [@filip-rs](https://github.com/filip-rs)

## Install

```bash
git clone https://github.com/tritacle/dotfiles-arch.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

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

- **Auto-tracking**: Install any package -> auto-tracked -> auto-committed -> auto-pushed
- **Conflict-free**: Safe to run install.sh multiple times

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
