#!/usr/bin/env bash
# Bootstrap these dotfiles: check dependencies, then stow the packages.
# Idempotent — safe to re-run after `git pull`.
#
#   ./install.sh            # all packages
#   ./install.sh zsh nvim   # only these
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_PACKAGES=(zsh starship nvim ghostty)
PACKAGES=("${@:-}")
[[ -z "${PACKAGES[*]}" ]] && PACKAGES=("${ALL_PACKAGES[@]}")

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

# ── Dependencies ─────────────────────────────────────────────────────────
bold "Checking dependencies"
missing=0
check() { # check <command> <why> <arch-package>
  if command -v "$1" >/dev/null 2>&1; then ok "$1"
  else warn "$1 missing — $2 (arch: $3)"; missing=$((missing + 1)); fi
}
check stow        "required to symlink these dotfiles" stow
check zsh         "the shell"                          zsh
check starship    "the prompt"                         starship
check nvim        "the editor"                         neovim
check tree-sitter "builds nvim treesitter parsers"     tree-sitter-cli
check ghostty     "the terminal"                       ghostty
check mise        "runtime version manager (.zshrc)"   mise

if [[ -d "$HOME/.zprezto" ]]; then
  ok "prezto (~/.zprezto)"
else
  warn "prezto missing — clone it:"
  printf '      git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto\n'
  missing=$((missing + 1))
fi

# These dotfiles pin nvim-treesitter to its `main` branch, which needs nvim >= 0.12.
if command -v nvim >/dev/null 2>&1; then
  nvim_ver=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [[ "$(printf '%s\n0.12\n' "$nvim_ver" | sort -V | head -1)" != "0.12" ]]; then
    warn "nvim is $nvim_ver — these dotfiles need >= 0.12 (nvim-treesitter main branch)"
    missing=$((missing + 1))
  else
    ok "nvim $nvim_ver (>= 0.12)"
  fi
fi

(( missing > 0 )) && printf '\n  %d dependency issue(s) above. Stowing anyway.\n' "$missing"

# ── Stow ─────────────────────────────────────────────────────────────────
# --no-folding keeps ~/.config/zsh a real directory so runtime files
# (.zsh_history, .zcompdump) are not written back into this repo.
printf '\n'; bold "Stowing packages"
for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$DOTFILES/$pkg" ]]; then warn "no such package: $pkg"; continue; fi
  stow --no-folding --restow --dir="$DOTFILES" --target="$HOME" "$pkg"
  ok "$pkg"
done

# ── Secrets ──────────────────────────────────────────────────────────────
printf '\n'; bold "Secrets"
secrets="$HOME/.config/zsh/secrets.zsh"
if [[ -f "$secrets" ]]; then
  ok "$secrets exists"
else
  cp "$DOTFILES/zsh/.config/zsh/secrets.zsh.example" "$secrets"
  chmod 600 "$secrets"
  ok "created $secrets (gitignored) — add your keys there, not in .zshrc"
fi
chmod 600 "$secrets"

printf '\n'; bold "Done. Start a new shell (or: exec zsh)"
