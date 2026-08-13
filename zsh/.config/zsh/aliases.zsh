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

# ── pnpm ───────────────────────────────────────────────────────────────────
alias p='pnpm'

# ── git ────────────────────────────────────────────────────────────────────
# NOTE: `gir` is not a command, so this has never worked. Kept verbatim from
# .zshrc rather than "fixed" during the move — the obvious reading is
# `git reset --hard @{u}`, and silently turning a no-op into a hard reset is
# not a change to make on someone's behalf.
alias gro='gir --hard @{u}'

# -- Claude -----------------------------------------------------------------
# No `claude` alias. There was one pointing at ~/.claude/local/claude, an old
# install layout that no longer exists; it shadowed the working binary on PATH
# (~/.local/bin/claude -> ~/.local/share/claude/versions/…) and produced
# "no such file or directory". PATH already resolves it correctly.
alias claude-personal="CLAUDE_CONFIG_DIR=~/.claude-personal command claude"
