# =============================================================================
# Dotfiles Makefile
# =============================================================================
# Simple Makefile for managing dotfiles installation and maintenance
# =============================================================================

.PHONY: help install install-packages install-stow update clean list stow unstow

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
NC := \033[0m # No Color

# Get list of stow packages
PACKAGES := $(shell find . -maxdepth 1 -type d -not -path './.git' -not -path './scripts' -not -path './packages' -not -path './.github' -not -path './bin' -not -path '.' | sed 's|.\/||')

help: ## Show this help message
	@echo "$(BLUE)Dotfiles Management$(NC)"
	@echo "===================="
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Available packages:$(NC)"
	@for pkg in $(PACKAGES); do \
		echo "  - $$pkg"; \
	done

install: ## Full installation (packages + stow)
	@./install.sh

install-packages: ## Install packages only
	@./install.sh --packages

install-stow: ## Stow dotfiles only
	@./install.sh --stow

update: ## Update dotfiles (re-stow all packages)
	@./install.sh update

list: ## List all stow packages
	@echo "$(BLUE)Available packages:$(NC)"
	@for pkg in $(PACKAGES); do \
		if [ -L "$(HOME)/.config/$$pkg" ] || [ -L "$(HOME)/.$$pkg" ]; then \
			echo "  $(GREEN)✓$(NC) $$pkg (stowed)"; \
		else \
			echo "  $(YELLOW)○$(NC) $$pkg"; \
		fi \
	done

stow: ## Stow all packages (or specify PACKAGE=<name>)
ifdef PACKAGE
	@echo "$(BLUE)Stowing $(PACKAGE)...$(NC)"
	@stow --dotfiles -t $(HOME) $(PACKAGE) 2>/dev/null || stow --dotfiles --adopt -t $(HOME) $(PACKAGE)
	@echo "$(GREEN)✓$(NC) $(PACKAGE) stowed"
else
	@echo "$(BLUE)Stowing all packages...$(NC)"
	@for pkg in $(PACKAGES); do \
		stow --dotfiles -t $(HOME) $$pkg 2>/dev/null || stow --dotfiles --adopt -t $(HOME) $$pkg; \
		echo "  $(GREEN)✓$(NC) $$pkg"; \
	done
	@echo "$(GREEN)All packages stowed!$(NC)"
endif

unstow: ## Unstow all packages (or specify PACKAGE=<name>)
ifdef PACKAGE
	@echo "$(BLUE)Unstowing $(PACKAGE)...$(NC)"
	@stow -D --dotfiles -t $(HOME) $(PACKAGE)
	@echo "$(GREEN)✓$(NC) $(PACKAGE) unstowed"
else
	@echo "$(BLUE)Unstowing all packages...$(NC)"
	@for pkg in $(PACKAGES); do \
		stow -D --dotfiles -t $(HOME) $$pkg 2>/dev/null; \
		echo "  $(GREEN)✓$(NC) $$pkg"; \
	done
	@echo "$(GREEN)All packages unstowed!$(NC)"
endif

reinstall: unstow stow ## Unstow and restow all packages

clean: ## Clean up adopted files and backups
	@echo "$(YELLOW)Cleaning up backup files...$(NC)"
	@find $(HOME) -name "*.backup-*" -type f -delete 2>/dev/null || true
	@find $(HOME) -name "*.bak" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

check: ## Check stow status
	@echo "$(BLUE)Checking stow status...$(NC)"
	@./scripts/check.sh 2>/dev/null || echo "Check script not implemented yet"

backup: ## Backup current dotfiles
	@echo "$(BLUE)Backing up current dotfiles...$(NC)"
	@mkdir -p $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)
	@cp -L $(HOME)/.zshrc $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@cp -L $(HOME)/.tmux.conf $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@cp -L $(HOME)/.gitconfig $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@cp -rL $(HOME)/.config/nvim $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@echo "$(GREEN)Backup complete!$(NC)"
