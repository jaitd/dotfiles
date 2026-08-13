# User aliases. Sourced from .zshrc.

# ── apt ────────────────────────────────────────────────────────────────────
alias agi='sudo apt install'
alias agu='sudo apt update'
alias agU='sudo apt update && sudo apt upgrade'
alias agx='sudo apt remove'
alias agX='sudo apt purge'
alias agar='sudo apt autoremove'
alias acs='apt search'
alias acsh='apt show'
alias agls='apt list --installed'

# ── pulumi ─────────────────────────────────────────────────────────────────
alias pup='pulumi stack select && pulumi up'
alias pud='pulumi stack select && pulumi down'
alias pup-dev='pulumi stack select dev && pulumi up'
alias pud-dev='pulumi stack select dev && pulumi down'

# -- Claude -----------------------------------------------------------------
alias claude-personal="CLAUDE_CONFIG_DIR=~/.claude-personal command claude"
