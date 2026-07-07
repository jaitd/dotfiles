# Point zsh at the XDG config location; all other runcoms live in $ZDOTDIR.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Prezto: ensure non-login, non-interactive shells have a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
