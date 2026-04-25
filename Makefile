.PHONY: install test stow unstow list

install:
	./install.sh

test:
	./test.sh

stow:
	@for pkg in */; do \
		pkg="$${pkg%/}"; \
		[[ "$$pkg" == ".git" ]] && continue; \
		[[ "$$pkg" == ".github" ]] && continue; \
		[[ "$$pkg" == "packages" ]] && continue; \
		[[ "$$pkg" == "bin" ]] && continue; \
		[[ -d "$$pkg/.config" ]] || [[ -f "$$pkg/.zshrc" ]] || continue; \
		stow --dotfiles -t ~ "$$pkg" 2>/dev/null || stow --dotfiles --adopt -t ~ "$$pkg"; \
		echo "Stowed $$pkg"; \
	done

unstow:
	@for pkg in */; do \
		pkg="$${pkg%/}"; \
		stow -D --dotfiles -t ~ "$$pkg" 2>/dev/null; \
	done

list:
	@for pkg in */; do \
		pkg="$${pkg%/}"; \
		[[ "$$pkg" == ".git" ]] && continue; \
		[[ "$$pkg" == ".github" ]] && continue; \
		[[ "$$pkg" == "packages" ]] && continue; \
		[[ -d "$$pkg/.config" ]] || [[ -f "$$pkg/.zshrc" ]] || continue; \
		if [[ -L "$$HOME/.config/$$pkg" ]] 2>/dev/null; then \
			echo "[x] $$pkg"; \
		else \
			echo "[ ] $$pkg"; \
		fi \
	done
