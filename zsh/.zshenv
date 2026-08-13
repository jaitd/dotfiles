# Export XDG_CONFIG_HOME rather than merely defaulting it: other tools read it,
# and the un-stowed ~/.zshenv this replaces was where it got exported.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Point zsh at the XDG config location; all other runcoms live in $ZDOTDIR.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Prezto: ensure non-login, non-interactive shells have a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
