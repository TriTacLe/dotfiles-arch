# Dotfiles

My Arch Linux dotfiles 

## **Credits:** @filip-rs

## Prerequisites

Install `stow`:
```bash
sudo pacman -S stow
```

## Install

### 1. Packages

```bash
cd ~/dotfiles

sudo pacman -S --needed - < pacman.txt

# Install AUR packages 
yay -S --needed - < aur.txt
```

### 2. Dotfiles

```bash
cd ~/dotfiles
stow . -t ~
```
``
