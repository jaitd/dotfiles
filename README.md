# dotfiles

Personal dotfiles, managed with [GNU Stow](https://gnu.org/software/stow/).

> ⚠️ **This repo is public.** Never commit secrets. Machine-local secrets go in
> `~/.config/zsh/secrets.zsh`, which is gitignored — see [Secrets](#secrets).

## Packages

| Package    | Installs to                   | What it is |
|------------|-------------------------------|------------|
| `zsh`      | `~/.zshenv`, `~/.config/zsh/` | Zsh + [Prezto](https://github.com/sorin-ionescu/prezto), XDG layout |
| `starship` | `~/.config/starship.toml`     | [Starship](https://starship.rs) prompt (kanagawa, ~5ms) |
| `nvim`     | `~/.config/nvim/`             | Neovim, lazy.nvim, LSP + treesitter |
| `ghostty`  | `~/.config/ghostty/config`    | [Ghostty](https://ghostty.org) terminal |
| `claude`   | `~/.claude/`, `~/.claude-personal/` | Claude Code settings + statusline, rendered by Starship to match the shell prompt |

The `claude` package covers both accounts: the default profile in `~/.claude`,
and the personal one in `~/.claude-personal` that the `claude-personal` alias
selects via `CLAUDE_CONFIG_DIR`. Both point their statusline at the single
`~/.claude/statusline.sh` symlink, which badges the line with the active
profile (` default` / `󰋜 personal`) so it is obvious which account a session
is billing to.

## Install

```sh
git clone git@github.com:jaitd/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh            # checks deps, stows every package
./install.sh zsh nvim   # or stow only certain packages
```

`install.sh` is idempotent — safe to re-run after pulling.

## Dependencies

`install.sh` warns about anything missing.

| Tool | Why | Arch package |
|------|-----|--------------|
| `stow` | symlink manager | `stow` |
| `zsh` | shell | `zsh` |
| Prezto | zsh framework, cloned to `~/.zprezto` | see below |
| `starship` | prompt | `starship` |
| `neovim` ≥ 0.12 | editor | `neovim` |
| `tree-sitter` CLI | **required** to build treesitter parsers | `tree-sitter-cli` |
| `ghostty` | terminal | `ghostty` |
| a Nerd Font | prompt/editor glyphs | `ttf-font-nerd` (Ghostty bundles one too) |
| `mise` | runtime version manager (used by `.zshrc`) | `mise` |
| `jq` | parses Claude Code's statusline JSON | `jq` |

Prezto (the framework itself is *not* vendored here):

```sh
git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
```

## Layout notes

**Zsh uses the XDG layout.** `~/.zshenv` is the only file in `$HOME`; it sets
`ZDOTDIR=~/.config/zsh`, and every other runcom (`.zshrc`, `.zpreztorc`,
`.zprofile`, `.zlogin`, `.zlogout`) lives there. The Prezto framework stays at
`~/.zprezto`. Shell history (`~/.config/zsh/.zsh_history`) is gitignored.

Stow runs with `--no-folding`, so directories like `~/.config/zsh` stay real
directories with per-file symlinks. Otherwise runtime files (history,
`.zcompdump`) would be written back into this repo.

## Secrets

`.zshrc` is tracked in this **public** repo, so API keys must never go there:

```sh
cd ~/.config/zsh
cp secrets.zsh.example secrets.zsh
chmod 600 secrets.zsh
$EDITOR secrets.zsh          # export GEMINI_API_KEY="..." etc.
```

`.zshrc` sources `$ZDOTDIR/secrets.zsh` when present. It is gitignored.

## Neovim 0.12 requirement

`main` is the only branch. It **requires Neovim ≥ 0.12 and the `tree-sitter`
CLI** (`tree-sitter-cli`), because nvim-treesitter is pinned to its `main`
branch.

Why: nvim-treesitter's `master` branch is frozen upstream and crashes on
Neovim 0.12's treesitter injection handling (`vim.treesitter.get_range` receives
a nil node → `attempt to call method 'range' (a nil value)`). Its `main` branch
is the supported path, and it builds parsers from source with the `tree-sitter`
CLI — without that binary, parser installs fail with `ENOENT ... 'tree-sitter'`
and highlighting silently won't work.

Before pulling these dotfiles onto a machine:

```sh
nvim --version | head -1        # must be >= 0.12
sudo pacman -S tree-sitter-cli  # required to build parsers
```

`install.sh` checks both and warns if either is missing.
