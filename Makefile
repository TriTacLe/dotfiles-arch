.PHONY: install stow unstow list verify hook help

# Single source of truth for stow logic lives in scripts/config.sh.
# Each target shells out to bash so we can `source` the library.

help:
	@echo "Targets:"
	@echo "  make install   Run full installer (./install.sh)"
	@echo "  make stow      Stow all packages (./install.sh --stow)"
	@echo "  make unstow    Unstow all packages"
	@echo "  make list      Show stow status of each package"
	@echo "  make verify    Run system verification checks"
	@echo "  make hook      Install pacman auto-track hook (sudo)"

install:
	./install.sh

stow:
	./install.sh --stow

unstow:
	@bash -c 'source scripts/config.sh; while read pkg; do \
		stow -D --dotfiles -t "$$HOME" "$$pkg" 2>/dev/null && echo "Unstowed $$pkg"; \
	done < <(list_stow_packages)'

list:
	@bash -c 'source scripts/config.sh; while read pkg; do \
		marker="$$HOME/.config/$$pkg"; \
		[ -L "$$marker" ] && echo "[x] $$pkg" || echo "[ ] $$pkg"; \
	done < <(list_stow_packages)'

verify:
	./verify-system.sh

hook:
	./install-hook.sh
