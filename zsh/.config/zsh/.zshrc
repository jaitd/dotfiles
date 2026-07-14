#
# Executes commands at the start of an interactive session.
#
# NOTE: this file is tracked in a PUBLIC dotfiles repo. Never put secrets here —
# put them in $ZDOTDIR/secrets.zsh, which is gitignored and sourced below.
#

# Source Prezto.
if [[ -s "$HOME/.zprezto/init.zsh" ]]; then
  source "$HOME/.zprezto/init.zsh"
fi

# Deno / Fly
export DENO_INSTALL="$HOME/.deno"
export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$DENO_INSTALL/bin:$FLYCTL_INSTALL/bin:$PATH"

# pipx / user binaries (also added by .zprofile; guard against duplicates)
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$PATH:$HOME/.local/bin"

# n (node version manager)
export N_PREFIX="$HOME/n"
[[ ":$PATH:" == *":$N_PREFIX/bin:"* ]] || export PATH="$PATH:$N_PREFIX/bin"

# Turso
[[ ":$PATH:" == *":$HOME/.turso:"* ]] || export PATH="$PATH:$HOME/.turso"

# Pulumi
[[ ":$PATH:" == *":$HOME/.pulumi/bin:"* ]] || export PATH="$PATH:$HOME/.pulumi/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ ":$PATH:" == *":$PNPM_HOME:"* ]] || export PATH="$PNPM_HOME:$PATH"

# Rust / cargo — rustup manages the toolchain; `cargo install` drops binaries
# into ~/.cargo/bin (e.g. cargo-expand), which must be on PATH to run them.
[[ ":$PATH:" == *":$HOME/.cargo/bin:"* ]] || export PATH="$PATH:$HOME/.cargo/bin"

# envman
[[ -s "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"

# Google Cloud SDK (TODO: relocate out of ~/Downloads to e.g. ~/.local/share)
GCLOUD_SDK="$HOME/Downloads/google-cloud-sdk"
[[ -f "$GCLOUD_SDK/path.zsh.inc" ]] && source "$GCLOUD_SDK/path.zsh.inc"
[[ -f "$GCLOUD_SDK/completion.zsh.inc" ]] && source "$GCLOUD_SDK/completion.zsh.inc"

# mise (runtime version manager)
eval "$(mise activate zsh)"

# Aliases
alias p="pnpm"
# NOTE: `gir` is not a command — this alias has never worked. Did you mean
# `git reset --hard @{u}`? Left as-is because that would be destructive.
alias gro="gir --hard @{u}"
alias claude="$HOME/.claude/local/claude"

# Secrets (API keys, tokens). Gitignored — see secrets.zsh.example.
[[ -f "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"

# Starship prompt (replaces Spaceship — see ~/.config/starship.toml). Keep this
# last so it initializes after Prezto and wins the prompt.
eval "$(starship init zsh)"
. "/tmp/claude-1000/-home-jait-dev-237labs-certifications-standalone/41fa2a16-01f0-4919-9b7c-5bc45983768a/scratchpad/deno-latest/env"
