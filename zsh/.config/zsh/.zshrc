#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "$HOME/.zprezto/init.zsh" ]]; then
  source "$HOME/.zprezto/init.zsh"
fi

# Deno
export DENO_INSTALL="/home/jait/.deno"
export FLYCTL_INSTALL="/home/jait/.fly"
export PATH="$DENO_INSTALL/bin:$FLYCTL_INSTALL/bin:$PATH"

# Created by `pipx` on 2024-04-19 11:58:50
export PATH="$PATH:/home/jait/.local/bin"

export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

# Turso
export PATH="$PATH:/home/jait/.turso"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/jait/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/jait/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/jait/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/jait/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
eval "$(mise activate zsh)"

alias p="pnpm"
alias gro="gir --hard @{u}"

# add Pulumi to the PATH
export PATH=$PATH:/home/jait/.pulumi/bin

# pnpm
export PNPM_HOME="/home/jait/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
alias claude="/home/jait/.claude/local/claude"

# Starship prompt (replaces Spaceship — see ~/.config/starship.toml). Keep this
# last so it initializes after Prezto and wins the prompt.
eval "$(starship init zsh)"
