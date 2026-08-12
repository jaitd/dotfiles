# sidecar.nvim — Design

A coding agent in a Neovim sidebar, scoped to *your Neovim config* and given a
deliberately tiny, enforced window into the running session: read the live
state, reload the config, report what broke. Not a coding assistant — a
config-tinkering partner that can see the editor it is editing.

- **Status**: design, pre-implementation
- **Date**: 2026-08-12
- **Name**: `sidecar.nvim` provisional
- **Packaging**: standalone plugin repo; dotfiles consume it as a lazy.nvim spec
- **Runtime**: embedded [pi][pi] pinned and vendored by the plugin, on OpenRouter. Requires Node.
- **Scope of this doc**: the plugin only — sidebar, bridge, verbs, embedded agent.

---

## 1. Motivation

Editing a Neovim config is a blind loop. You change a Lua file, restart, see
whether it took, read a stack trace scrolled off the top of `:messages`, guess,
repeat. An agent helping with that config is blinder still: it can read the
files, but it cannot see the instance those files produced — which plugins
actually loaded, which lazy-loaded and why, which LSP attached, what the last
error said.

Closing that loop is the whole point. Give an agent (a) the config directory as
its working set and (b) two capabilities — *look at the live session* and
*reload and tell me what broke* — and config work becomes iterative instead of
speculative.

The general-purpose version of this is solved: `sidekick.nvim`,
`claudecode.nvim`, `opencode.nvim` all put an agent next to your code with rich
editor context. This is the opposite bet: **narrower scope, deeper access.**

## 2. Guiding principles

Load-bearing. Every decision below derives from one of these.

1. **The config directory is the world.** The agent launches with cwd set to the
   resolved config dir. It helps with Neovim setup; it is not a general coding
   assistant. That job belongs to `sidekick.nvim` et al., and the two can coexist.
2. **Narrow is enforced in Neovim, not requested in a prompt.** The RPC entry
   point is a closed dispatch table of verbs, never `nvim_exec_lua` with
   agent-supplied code. A skill that says "please don't run `:qa`" enforces
   nothing; a dispatch table with no `quit` verb enforces something.
3. **Read, plus exactly one write.** `reload` is the only verb with side
   effects. Everything else observes. This line is defensible and easy to audit;
   `open_file` / `set_cursor` / `feedkeys` are not in scope (§11).
4. **One agent, pinned and embedded; one transport, generic.** v1 ships a
   vendored pi at a known version rather than adapting to whatever CLI the user
   has. This is what makes principle 2 *true* instead of aspirational (§5.7).
   The bridge underneath stays a plain CLI, so replacing the agent later is a
   new adapter, not a new architecture.
5. **Tokens are a budget.** Default `state` output is small and composable. An
   agent that burns 15k tokens on editor context before its first thought is
   worse than one that asks for what it needs.

## 3. Architecture

```
┌─ Neovim ────────────────────────────────────────────────────────┐
│                                                                 │
│  lua/sidecar/ui.lua        vsplit, term job, toggle, pi launch   │
│  lua/sidecar/api.lua       ◄── the dispatch table (§5.3)         │
│         ▲                      { state, reload, diagnostics }    │
│         │ rpcrequest via v:servername                            │
│  ┌──────┴──────────────────────────────────────────────────┐    │
│  │ terminal buffer, cwd = resolve(stdpath("config"))       │    │
│  │                                                          │    │
│  │   vendor/…/bin/pi  --provider openrouter                 │    │
│  │        --tools read,edit,write,grep,find,ls,nvim_*       │    │
│  │        -e extension/nvim.ts        ◄── §5.7              │    │
│  │      │ spawns per tool call                              │    │
│  │      └── bin/nvim-sidecar          ◄── the client (§5.4) │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

Three pieces, one shared core. The verb table exists once, in Lua, inside the
instance being inspected. The client is dumb transport. The pi extension is a
thin wrapper that turns each verb into a registered tool.

Note what is *absent* from the tool list: `bash`. That single omission is what
§6 rests on.

## 4. Verified mechanics

Prototyped before designing on top of them, against nvim 0.12.4.

| Mechanism | Result |
|---|---|
| `$NVIM` in terminal children | **Confirmed.** A `jobstart({term=true})` child sees `NVIM=/run/user/1000/…`, the parent's socket. No port allocation, lockfile, or discovery protocol needed. |
| `nvim -l` as an RPC client | **Confirmed.** `vim.fn.sockconnect('pipe', addr, {rpc=true})` + `vim.rpcrequest` returns live state: `{"bufs":1,"ver":"0.12","cwd":"…"}`. |
| `nvim -l` as a stdio JSON-RPC server | **Confirmed.** `io.read("l")` → `vim.json.decode` → respond on stdout. A complete MCP server in pure Lua, zero Node/Python/luarocks. |
| Config dir resolution | `~/.config/nvim` is a stow symlink to `~/dotfiles/nvim/.config/nvim`; `git rev-parse --show-toplevel` from there resolves to `~/dotfiles`. |
| `vim.fn.termopen` | Deprecated at 0.11+. Use `jobstart({term = true})`. |
| pi provider | `OPENROUTER_API_KEY` env var, provider id `openrouter`. Checked against pi 0.79.10's bundled `docs/providers.md`. |
| pi tool gating | `--tools <list>` is an allowlist spanning built-in *and* extension tools; `--exclude-tools`, `--no-builtin-tools`, `--no-tools` also available. |
| pi extension API | `pi.registerTool({name, label, description, parameters, execute})` with typebox schemas; `.ts` loaded directly via `-e`, no build step. |
| pi permission hook | `pi.on("tool_call", …)` can return `{block: true, reason}` — a real gate, not advice. |
| pi hermetic flags | `--no-extensions`, `--no-skills`, `--no-context-files`, `--no-prompt-templates` — ambient user config can be excluded from the sidecar session. |

The `nvim -l` result is the load-bearing one: **the plugin ships one Lua file as
its client and depends on nothing that isn't already installed.**

## 5. Components

### 5.1 Sidebar (`sidecar/ui.lua`)

Owned rather than delegated — it is roughly 150 lines and a dependency here
would drag in a general-purpose agent framework we explicitly don't want.

- Vertical split, configurable `width` (default 80 columns) and `side`
  (default `right`), `winfixwidth` so sibling splits don't reflow it.
- `jobstart({ cmd }, { term = true, cwd = <resolved config dir>, env = … })`.
- **Toggle hides, never kills.** The terminal buffer persists; the job keeps
  running. Closing the window is `:hide`, not `:bdelete`. A killed session
  loses agent context, which is the expensive thing in the room.
- Buffer-local: no number/relativenumber/signcolumn, `bufhidden=hide`.
- Terminal-mode escape hatch mapped buffer-locally, so `<Esc>` still reaches the
  agent's TUI (pi uses `<Esc>` internally). Default `<C-\><C-n>`
  stays; add `<C-;>` or similar for window nav.
- Autocmd on `TermClose` clears the stored job handle so toggle re-launches.

### 5.2 Embedded pi runtime

pi is vendored by the plugin at a pinned version, not discovered on `PATH`. A
lazy.nvim `build` step installs it into the plugin directory:

```
build = "npm install --no-save --prefix vendor @earendil-works/pi-coding-agent@<pinned>"
→ launch vendor/node_modules/.bin/pi
```

Rationale: a config assistant that breaks because the user upgraded their global
pi is worse than no config assistant. Pinning also means the extension API
(§5.7) is a fixed target — the whole enforcement story depends on flags and hook
names that a major version could move. Vendoring into the plugin dir rather than
installing globally keeps the user's own pi installation and settings untouched.

Cost, stated plainly: **this introduces a Node runtime dependency** into a plugin
whose other two components are dependency-free Lua. That is the price of a real
permission gate, and it is worth it (§6), but it should be a conscious trade
rather than a surprise. `install.sh`-style dependency checking should verify
`node` alongside `jq` and `stow`.

Provider is OpenRouter: `--provider openrouter --model <configured>`, key from
`OPENROUTER_API_KEY`. In this dotfiles setup that belongs in
`~/.config/zsh/secrets.zsh`, which is gitignored — **the repo is public, so the
key must never reach plugin config or this spec.** The plugin reads it from the
environment and fails with a clear message when unset.

Model choice is config, not code (§7). Config tinkering is a cheap workload —
mostly reading small Lua files and short reasoning — so a mid-tier model is the
sensible default and the user can raise it per-session with pi's `Ctrl+P`
cycling.

The session launches hermetically: `--no-extensions` (then `-e` our own),
`--no-skills`, `--no-prompt-templates`. The user's ambient pi setup is for their
coding work; the sidecar's tool surface must be exactly what this plugin defines
and nothing a stray extension in `~/.pi/agent/extensions/` adds. `AGENTS.md`
discovery stays *on* — a config-dir `AGENTS.md` is a legitimate way to teach the
agent about this particular Neovim setup.

### 5.3 The bridge (`sidecar/api.lua`) — where narrow is enforced

A single RPC entry point over a closed table:

```lua
local VERBS = { state = …, reload = …, diagnostics = … }

function M.call(verb, args)
  local fn = VERBS[verb]
  if not fn then return { ok = false, error = "unknown verb: " .. verb } end
  local ok, res = pcall(fn, args or {})
  return ok and { ok = true, result = res } or { ok = false, error = tostring(res) }
end
```

The client invokes `nvim_exec_lua("return require('sidecar.api').call(...)", …)`
with the verb name as *data*. There is no path from agent input to arbitrary Lua.
Every verb `pcall`s — a broken verb must never leave the user's editor wedged.

### 5.4 The client (`bin/nvim-sidecar`)

One `nvim -l` script: `nvim-sidecar state --what=buffers,diagnostics` prints
JSON to stdout. The pi extension spawns it per tool call — roughly 50ms of
process startup, irrelevant next to an LLM round trip, and worth it to keep a
single dispatch path shared by every future consumer.

Keeping this a standalone CLI rather than folding it into the extension is the
seam that makes principle 4's second half real: an MCP mode (`initialize` /
`tools/list` / `tools/call` over line-delimited stdin, verified feasible in §4)
is perhaps 80 lines on top, if a Claude Code adapter is ever wanted. Out of
scope for v1 (§11).

Socket address from `$NVIM_SIDECAR_ADDR`, falling back to `$NVIM`. Exit non-zero
with a readable message when the socket is gone (nvim quit, wrong instance) —
agents recover well from clear errors and badly from empty output.

**Pitfall**: with `NVIM_APPNAME` set, `nvim --server` writes a warning to
*stdout*, corrupting parsed output. Using `nvim -l` + `sockconnect` directly
sidesteps this entirely — a second reason to prefer it over shelling out to
`nvim --server --remote-expr`.

### 5.5 Verb: `state`

Parameterized and composable. Default set is deliberately thin; expensive
sections are opt-in.

| Section | Default | Contents |
|---|:---:|---|
| `nvim` | ✅ | version, resolved config dir, `NVIM_APPNAME`, startup time |
| `buffers` | ✅ | listed bufs: path relative to config dir, filetype, modified, loaded |
| `diagnostics` | ✅ | **counts** by severity per file; full items only when requested |
| `plugins` | ✅ | lazy.nvim: name, loaded, lazy, load reason — **errored plugins in full** |
| `windows` | ➖ | layout, current window/buffer, cursor position |
| `lsp` | ➖ | attached clients per buffer, root_dir, server capabilities summary |
| `keymaps` | ➖ | mode, lhs, desc — large, and rarely what the question needs |
| `messages` | ➖ | tail of `:messages` |

Paths are emitted relative to the config dir so the agent's file tools and the
state output speak the same language.

### 5.6 Verb: `reload`

The payoff verb, and the one with teeth.

```
1. snapshot len(:messages)
2. purge package.loaded for modules under the config dir
     — EXCEPT sidecar.*        (never unload the plugin mid-call)
     — EXCEPT config.lazy      (see below)
3. re-require config.options, config.keymaps, config.autocmds  (each pcall'd)
4. collect: errors[], messages delta, reloaded[], duration_ms
```

Three constraints fall out of this config's actual shape:

- **Never unload `sidecar.*`.** The reload is running *inside* a terminal buffer
  owned by the plugin being reloaded. Purging its own modules mid-call is a
  self-inflicted crash.
- **Skip `config.lazy`.** `init.lua` is leader vars plus four requires; three
  are idempotent, but `config.lazy` calls `require("lazy").setup()` and calling
  that twice is not a no-op. Plugin-spec changes route to `:Lazy reload <name>`
  as a separate concern, not through this verb.
- **Side effects don't unregister.** Reloading a file does not remove the
  autocmds, keymaps, or highlight groups it previously created. This config is
  already safe here — every augroup in `config/autocmds.lua` is named and
  created with `{ clear = true }` — but the verb must document the requirement,
  because it is a property of the *user's* config, not of the plugin. Keymaps
  whose `lhs` is renamed will leak the old binding; that is a known and accepted
  limitation of hot reload.

Return value is the feature: `{ ok, errors[], messages[], reloaded[], duration_ms }`.
An agent that can edit a file, reload, and read the resulting stack trace has a
closed feedback loop. That is worth more than any amount of read-only
introspection.

### 5.7 The enforced tool surface

The agent needs to *edit* config files, so a bare `--no-builtin-tools` is too
strong — it would leave an assistant that can look but not help. The surface is
therefore an explicit allowlist:

```
--tools read,edit,write,grep,find,ls,nvim_state,nvim_reload,nvim_diagnostics
```

`bash` is absent, and that is the whole design. **Without a shell there is no
path from the agent to `nvim --server`, to `$NVIM`, to `git`, or to any
process it did not get handed.** The residual surface is file I/O plus three
verbs, and file I/O is gated below.

The pi extension (`extension/nvim.ts`) is thin — one `registerTool` per verb,
each shelling out to `bin/nvim-sidecar` and returning its JSON as a text content
block. Schemas via typebox, mirroring §5.5's section list.

A `pi.on("tool_call")` handler provides the second layer, confining file tools
to the config tree:

```typescript
pi.on("tool_call", async (event, ctx) => {
  if (!FILE_TOOLS.has(event.toolName)) return;
  const target = path.resolve(ctx.cwd, event.input.path);
  if (!target.startsWith(CONFIG_ROOT + path.sep)) {
    return { block: true, reason: `outside the Neovim config: ${target}` };
  }
});
```

This matters more than it looks (§6): cwd is where the agent *starts*, not a
boundary it cannot cross with a `../../`. The gate is what turns "scoped to your
config" from a convention into a check. Resolve symlinks on both sides before
comparing — `~/.config/nvim` is a stow symlink into the dotfiles repo, so the
real root is `~/dotfiles/nvim/.config/nvim` and a naive prefix test on the
unresolved path fails open.

## 6. Trust model

Embedding pi upgrades this section from a disclaimer to a claim. An earlier
draft of this design had to concede that any agent with a shell could run
`nvim --server "$NVIM" --remote-send ':qa!<CR>'` and that same-user processes
cannot be sandboxed from each other. With no `bash` tool, that concession
mostly retires: the agent has no way to reach the socket, or any other process.

The surface reduces to three layers, each independently checkable:

| Layer | Enforces | Where |
|---|---|---|
| Tool allowlist | no shell, no network, no process spawning | pi `--tools` (§5.7) |
| `tool_call` gate | file I/O confined to the resolved config tree | pi extension (§5.7) |
| Verb dispatch table | no arbitrary Lua in the editor; `reload` is the only side effect | `sidecar/api.lua` (§5.3) |

Belt and braces on top: launch the job with `NVIM` unset and hand the address to
the client as `NVIM_SIDECAR_ADDR`. Cheap, and it means a future loosening of the
tool list doesn't silently re-expose the socket.

What is still true, and should stay written down:

- **This is not a sandbox.** It is a tool surface. A pi bug, a prompt injection
  reaching a file tool with a path-traversal payload the gate mishandles, or a
  future flag change on upgrade could each widen it. The version pin (§5.2) is
  part of the trust model, not just packaging hygiene.
- **The config dir sits inside the dotfiles repo.** `~/.config/nvim` resolves to
  `~/dotfiles/nvim/.config/nvim`, whose git root is `~/dotfiles` — zsh, ghostty,
  claude, and this spec included. Without a shell the agent has no `git`, so
  this is now a *path* question that the §5.7 gate answers, rather than an
  unbounded one.
- **Prompt injection has a path in.** The agent reads config files, and config
  files are code the user pastes from the internet. The gate bounds the blast
  radius to the config tree; nothing bounds what it might write *within* it.
  `reload` executing attacker-influenced Lua in the user's editor is the real
  worst case here, and it is inherent to the feature rather than fixable.

## 7. Configuration surface (sketch)

```lua
require("sidecar").setup({
  model   = "openrouter/<mid-tier default>",  -- provider inferred from prefix
  cwd     = nil,                     -- default: resolve(stdpath("config"))
  window  = { side = "right", width = 80 },
  verbs   = { "state", "reload", "diagnostics" },  -- opt-out, never opt-in-to-more
  state   = { default = { "nvim", "buffers", "diagnostics", "plugins" } },
  keys    = { toggle = "<leader>ai", focus = "<leader>aa" },
})
```

Two properties this surface deliberately lacks:

- **No API key field.** `OPENROUTER_API_KEY` comes from the environment only.
  Config files get committed; this one to a public repo.
- **No `extra_tools` / `pi_args` escape hatch.** `verbs` is subtractive — the
  enforced set can only shrink from config, never grow. An escape hatch that
  lets a user append `--tools bash` would quietly undo §6, and the whole
  argument for embedding pi rather than adapting to it is that the flags are
  ours to guarantee.

## 8. Testing strategy

- **Bridge verbs** — headless nvim (`--headless --listen <sock>`), drive
  `bin/nvim-sidecar` against it, assert on JSON. This is exactly the prototype
  from §4 and needs no test framework beyond `assert`.
- **Reload correctness** — fixture config dir; assert a changed value takes
  effect, a syntax error is reported rather than thrown, `sidecar.*` survives,
  and autocmd counts don't grow across ten consecutive reloads.
- **The path gate** — the security-relevant test, and the one worth writing
  first. Table-driven: `../../.zshrc`, an absolute `/etc/passwd`, a symlink
  inside the config dir pointing out of it, and the legitimate case of
  `~/.config/nvim/lua/…` resolving through the stow symlink into the repo. Assert
  block/allow per case.
- **Launch flags** — assert the constructed argv contains no `bash` and no
  ambient-discovery flags, so a refactor can't quietly widen the surface.
- **Sidebar** — thinnest layer, least worth testing. Manual.

## 9. Build order

1. `sidecar/api.lua` with `state` only, plus `bin/nvim-sidecar`. Testable
   headlessly on day one, no UI, no agent.
2. pi extension registering `nvim_state`, run against a hand-launched
   `pi --tools …`. First end-to-end moment: an LLM answering a question about
   the live editor.
3. The `tool_call` path gate and its test table. Before any write tool is
   enabled, not after.
4. `reload`, with the three constraints from §5.6 and its reload-loop test.
5. Sidebar: split, term job, toggle-hides, vendored-pi launch with the full
   flag set.
6. `AGENTS.md` in the config dir teaching the agent this specific setup.

## 10. Open questions

- **`diagnostics` as a separate verb, or just a `state` section?** Currently
  both, which is redundant. Likely collapse into `state` once real usage shows
  whether full diagnostic items are ever wanted standalone.
- **Does `state` need history?** "What changed since the last reload" is a more
  useful question than "what is true now", but it implies retained state and a
  much larger design. Deferred until the thin version proves insufficient.
- **Multi-instance.** Two nvim instances, one sidebar each, both writing the
  same config. Out of scope for v1; the address plumbing already makes the
  session explicit, so this is a UX question rather than an architectural one.
- **Which model is actually good enough?** Config work is cheap per-token but
  needs real Lua fluency and Neovim API knowledge. Worth benchmarking a few
  OpenRouter mid-tier models on a fixed set of "why didn't this keymap take"
  tasks before fixing a default, rather than guessing.
- **Does vendoring survive lazy.nvim updates cleanly?** `build` re-runs on
  update, so a pin bump should just work — but `npm install --prefix` inside a
  plugin dir that lazy.nvim also `git checkout`s is worth verifying rather than
  assuming. Add `vendor/` to the plugin's `.gitignore`.

## 11. Explicitly out of scope

- **Write verbs.** No `open_file`, `set_cursor`, `feedkeys`, `exec_lua`,
  `buf_set_lines`. `reload` is the only side effect. (§2.3)
- **General coding assistance.** No selection at-mentions, no diff review, no
  file-watch reload of edited buffers. Use `sidekick.nvim` or
  `claudecode.nvim` alongside this; they occupy a different niche deliberately.
- **Agent choice.** One embedded, pinned pi (§5.2). No `agent = "claude"`
  option, no adapter table, no discovery of what's on `PATH`. The enforcement
  story in §6 is only as good as the weakest supported agent, so there is
  exactly one.
- **MCP.** pi has [no MCP support][pi-readme] by design, and with pi embedded
  nothing else consumes the bridge. The `nvim -l` client keeps an MCP mode cheap
  to add later (§5.4) — that seam is the reason, not a plan.
- **Anthropic's IDE WebSocket protocol.** `claudecode.nvim` implements it well,
  it is Claude-only, and its tool set is fixed at Anthropic's twelve — the
  opposite of a narrow custom surface. Wrong axis for this plugin.
- **Sandboxing claims.** See §6.

[pi]: https://github.com/badlogic/pi-mono
[pi-readme]: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/README.md
