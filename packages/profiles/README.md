# Package profiles

Each `<name>.txt` file in this directory is a profile - a curated subset of packages
suitable for a specific machine type or purpose. Profiles let you install just what
you need (e.g. only dev tools on a server, only desktop env on a fresh laptop)
without rewriting `packages.txt`.

## Format

One package per line, comments with `#`. Profiles can reference both pacman and
AUR packages - the installer figures out the source.

## Built-in profiles

- `minimal.txt`   - shell, git, editor, core CLI (works headless, no desktop)
- `desktop.txt`   - Hyprland + waybar + apps (assumes minimal already applied)
- `dev.txt`       - languages, build tools, containers
- `full.txt`      - everything (mirrors the union of packages.txt + aur.txt)

## Usage

```bash
./install.sh --profile minimal     # only essentials
./install.sh --profile dev         # only dev tools
./install.sh --profile desktop     # only desktop env
./install.sh                       # default: full install (unchanged)
```

Profiles are additive - run multiple in sequence to layer them:

```bash
./install.sh --profile minimal
./install.sh --profile dev
./install.sh --profile desktop
```

## Adding a new profile

Drop a new `<name>.txt` file. No code changes needed - the installer picks it up
automatically.
