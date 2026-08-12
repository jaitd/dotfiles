#!/usr/bin/env bash
# Claude Code statusline, rendered by Starship so it matches the shell prompt.
#
# Claude passes a JSON blob on stdin (cwd, model, output style, ...) and prints
# whatever this script writes to stdout as a single status line. The Starship
# half comes from the `claude` profile in ~/.config/starship.toml; the profile
# badge, model name and context gauge are added here since Starship knows
# nothing about them.
#
# Docs: https://docs.claude.com/en/docs/claude-code/statusline
set -uo pipefail

input=$(cat)
# Tab-delimited, so paths and model names containing spaces survive the read.
IFS=$'\t' read -r dir model used size pct transcript < <(jq -r '[
  (.workspace.current_dir // .cwd // "-"),
  # "Opus 4.8 (1M context)" -> "Opus 4.8"; the window size is shown separately.
  ((.model.display_name // "-") | sub(" *\\([^)]*context\\)$"; "")),
  (.context_window.total_input_tokens // 0),
  (.context_window.context_window_size // 0),
  (.context_window.used_percentage // 0 | round),
  (.transcript_path // "")
] | @tsv' <<<"$input")
[[ "$dir" == "-" ]] && dir="$PWD"

# Which config profile is this session running under? `claude-personal` (see
# ~/.config/zsh/aliases.zsh) exports CLAUDE_CONFIG_DIR=~/.claude-personal; the
# default profile leaves it unset and uses ~/.claude. transcript_path is the
# fallback for when this script is run without Claude's environment — the
# transcript always lives at <config dir>/projects/<slug>/<session>.jsonl.
config_dir=${CLAUDE_CONFIG_DIR:-}
if [[ -z "$config_dir" && "$transcript" == */projects/* ]]; then
  config_dir=${transcript%%/projects/*}
fi
# ".claude-personal" -> "personal", ".claude" (or nothing) -> "".
profile=${config_dir%/}
profile=${profile##*/}
profile=${profile#.claude}
profile=${profile#-}

# Colour and glyph, not just a word: the point is to notice at a glance which
# account is picking up the tab before sending a prompt, not to read it. Both
# profiles get a badge — an empty slot would be indistinguishable from a
# statusline that failed to work out the profile at all.
# Glyphs are codepoint escapes, not pasted literals: the raw bytes do not
# survive a round trip through every editor and patch tool.
case "$profile" in
  '')       icon=$'\U0000f0b1' colour='1;34' label='default'  ;; # nf-fa-briefcase
  personal) icon=$'\U000f02dc' colour='1;35' label='personal' ;; # nf-md-home
  *)        icon=$'\U0000f007' colour='1;36' label="$profile" ;; # nf-fa-user
esac
badge=$'\033['$colour'm'$icon' '$label$'\033[0m'

# --path resolves git/language modules against Claude's cwd; --logical-path is
# needed as well, or the [directory] module still renders this script's own cwd.
# STARSHIP_SHELL is cleared because an inherited "zsh" makes Starship emit
# %{...%} escape wrappers, which Claude would print literally.
prompt=$(STARSHIP_SHELL= starship prompt --profile claude \
  --path "$dir" --logical-path "$dir" 2>/dev/null)

# add_newline puts a blank line before the shell prompt; a statusline is one line.
prompt=${prompt#$'\n'}

# 43501 -> "44k", 1000000 -> "1M"; keeps the segment a fixed, glanceable width.
human() {
  local n=$1
  if   (( n >= 1000000 )); then printf '%sM' "$(( (n + 50000) / 1000000 ))"
  elif (( n >= 1000 ));    then printf '%sk' "$(( (n + 500) / 1000 ))"
  else printf '%s' "$n"; fi
}

printf '%s ' "$badge"
printf '%s' "${prompt%"${prompt##*[![:space:]]}"}" # trailing-space trim
[[ "$model" != "-" ]] && printf ' \033[2m(%s)\033[0m' "$model"

if (( size > 0 )); then
  # Green while there is room, yellow past 60%, red past 80% — the point is to
  # notice compaction coming before it happens, not to read exact numbers.
  if   (( pct >= 80 )); then colour='1;31'
  elif (( pct >= 60 )); then colour='1;33'
  else colour='32'; fi
  printf ' \033[%sm◧ %s%%\033[0m \033[2m%s/%s\033[0m' \
    "$colour" "$pct" "$(human "$used")" "$(human "$size")"
fi
printf '\n'
