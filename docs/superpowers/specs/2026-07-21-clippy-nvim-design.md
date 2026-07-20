# clippy.nvim — Design

An ambient + on-demand assistant for Neovim that watches how you actually
edit, notices when a shorter path existed in *your own* config, and surfaces
tips — while learning which tips land for *you*. A learning vehicle for pushing
LLMs as far as they'll go inside an editor, not a minimal-viable helper.

- **Status**: design, pre-implementation
- **Date**: 2026-07-21
- **Packaging**: standalone plugin repo (`clippy.nvim`); dotfiles consume it as a lazy.nvim spec
- **Scope of this doc**: the plugin only. Hosted inference API, cloud dashboard, and model training are explicitly out of scope and referenced only where a seam must exist for them.

---

## 1. Motivation

A rich Neovim config accumulates capability faster than the user's muscle
memory does. You install `gd`, project-wide rename, `conform.nvim`
format-on-save, Telescope pickers — and then keep reaching for the mouse, the
long path, the manual reformat. The static discovery layer already present
(`which-key`, `precognition`, `hardtime`) tells you *what keys exist*; it does
not tell you *what you personally should have done just now instead*.

clippy.nvim closes that gap: it observes editing, detects moments of friction,
and — grounded in a live inventory of what this specific config can do —
suggests the shorter path. It is built for **anyone's** config, so nothing
about capabilities is hardcoded; everything is discovered at runtime.

## 2. Guiding principles

These are load-bearing. Every component decision derives from one of them.

1. **Nothing is hardcoded per user.** Tips are claims relating *discovered*
   inventory, *observed* usage, and *captured* episodes. There is no curated
   tip database, because there cannot be one that is right for two different
   configs.
2. **Don't compress early (the spine).** The raw event stream is retained.
   Every processing stage is a *non-destructive view* that annotates the
   stream, never a lossy handover that replaces it with a summary. This is the
   voice-model insight: pipeline handovers throw away the "prosody" of editing
   (hesitation, false-starts, timing) that intent inference depends on.
3. **Local-first, opt-in-everything.** With zero configuration the plugin is
   useful and nothing leaves the machine. Every path that sends data anywhere
   (the LLM backends) is an explicit, configured choice with redaction applied.
4. **Propose / dispose / teach.** Generators *propose* candidate tips; a local
   bandit *disposes* (ranks/selects) per-user; the feedback loop *teaches* the
   bandit. The LLM never personalizes in-weights; adaptation to *you* is the
   bandit's job, online and local.
5. **Everything is an experiment harness.** Segmenters and tip backends are
   pluggable over the identical stream, so a rules baseline and an LLM variant
   can run side by side and be diffed. This is a learning project; comparison
   is a first-class feature, not an afterthought.

## 3. The four pillars

Every tip is a claim relating these four.

| Pillar | What it is | Source | Persistence |
|--------|-----------|--------|-------------|
| **Inventory** | What this config *can* do — the vocabulary of possible tips | Enumerated live: keymaps per mode, loaded plugins & specs, LSP client capabilities per buffer, user commands, options | Cached in memory, rebuilt on plugin load / `LspAttach` |
| **Usage** | How often each capability is actually invoked | Derived from the stream (keystroke→keymap resolution, command names) | JSON on disk, across sessions |
| **Episodes** | Bounded windows of activity — a pointer into the retained stream plus annotations | Segmenters over the stream | Recent N on disk (rolling) |
| **Feedback** | Outcome of every shown tip: acted-on / dismissed / ignored | Delivery UI + acted-on detection | JSON on disk — bandit state *and* future training set |

Coverage gaps — "capabilities you've never touched" — fall out for free as
**inventory − usage**, needing no episodes at all. Likely the first visible win.

## 4. Architecture

```
                    ┌─────────────────────────────────────────┐
   autocmds ───┐    │            EVENT STREAM (retained)       │
   vim.on_key ─┼───▶│  ring buffer of rich typed events        │
   cmd hooks ──┘    │  {t, type, payload, buf, mode, cursor}   │
                    └───────┬─────────────┬───────────┬────────┘
                            │             │           │
                   ┌────────▼───┐  ┌──────▼─────┐  ┌──▼────────┐
                   │ USAGE      │  │ SEGMENTERS │  │ INVENTORY │
                   │ counters   │  │ (views)    │  │ (live enum)│
                   └────────┬───┘  │  friction  │  └──┬────────┘
                            │      │  idle*     │     │
                            │      │  semantic* │     │
                            │      │  llm*      │     │
                            │      └──────┬─────┘     │
                            │             │ episodes  │
                            │             │ (pointer + annotations)
                            │             ▼           │
                            │      ┌──────────────────▼──┐
                            └─────▶│  TIP BACKENDS        │
                     coverage ─────│  • local rules       │
                     = inv − use   │  • llm (per-episode) │
                                   │  • llm (periodic)    │
                                   │  • coverage diff     │
                                   └──────┬───────────────┘
                                          │ candidate tips
                                          ▼
                                   ┌──────────────┐   feedback
                                   │  RANKER      │◀──────────┐
                                   │  bandit      │           │
                                   └──────┬───────┘           │
                                          │ chosen tip        │
                                          ▼                   │
                                   ┌──────────────┐  outcome  │
                                   │  DELIVERY UI │───────────┘
                                   │  ambient +   │
                                   │  :Clippy ask │
                                   └──────────────┘
```

`* = designed-for interface, not built in the first pass`

The stream is the only thing at the bottom. Usage, Inventory, Segmenters are
all **readers**. Segmenters produce episodes that *reference* stream ranges
rather than copying+compressing them — that is principle 2 made concrete.

## 5. Components

### 5.1 Event stream (capture)

- **Sources**: Neovim autocmds (`ModeChanged`, `CursorMoved`, `BufEnter`,
  `BufWritePost`, `CmdlineEnter`/`Leave`, `TextChangedI`/`TextChanged`,
  `SearchWrapped`, etc.), `vim.on_key` for raw keystroke capture, and light
  hooks on command dispatch.
- **Event shape**: `{ t = monotonic_ns, type, payload, buf, win, mode,
  cursor = {row, col} }`. `type` is a small closed set (`key`, `mode`, `move`,
  `bufenter`, `write`, `cmd`, `search`, `undo`, `help`, `mouse`, …).
- **Retention**: a fixed-size in-memory **ring buffer** (config: N events or T
  seconds). This is the raw, uncompressed record principle 2 protects. Episodes
  hold `{ ring_start_seq, ring_end_seq }` into it plus annotations.
- **Overhead budget**: `vim.on_key` fires on every keystroke, so the hot path
  must be allocation-light — append a value into a preallocated ring slot, no
  table churn per key. Capture is gated by a master enable flag so it can be
  turned fully off.

### 5.2 Inventory (capability enumeration)

- Built by querying Neovim live, never from a static list: `nvim_get_keymap`
  across modes, `nvim_get_commands`, loaded-plugin introspection (lazy.nvim
  spec / `package.loaded`), per-buffer LSP client capabilities, relevant
  options.
- Normalized into **capability records**: `{ id, kind, lhs/name, desc, source,
  rhs_summary }` where `id` is a stable key usable by usage counters and tips.
- Rebuilt on `VeryLazy`, `LspAttach`, and on demand. Cached otherwise.

### 5.3 Usage (counters)

- Resolves stream events to capability ids: keystroke sequences → matched
  keymap `lhs`; `cmd` events → command name. Increments a counter per id.
- Persisted as JSON; merged across sessions. Feeds coverage diff and gives tips
  their "you've used the alternative N times" grounding.

### 5.4 Segmenters (pluggable views → episodes)

- **Interface**: a segmenter consumes the event stream (via a subscription or a
  windowed pull) and emits `Episode { ring_start_seq, ring_end_seq, markers,
  annotations }`. It does **not** own or mutate the stream.
- **FrictionSegmenter** (first, rules-based): fires on friction markers — undo
  immediately after a sequence, aborted command, `:h` lookup, long pause before
  acting, repeated/narrowing searches, mouse reach for a navigable target. On a
  marker it bounds an episode around the struggle window.
- **IdleSegmenter** / **SemanticSegmenter** (designed-for): burst-between-pauses
  and state-change-bounded, respectively. Same interface, added later, read the
  same stream — so they can run *alongside* friction and be compared.
- **LLMSegmenter** (designed-for, the end-to-end seam): a model reads a rolling
  stream window and decides boundaries + intent directly, collapsing
  segment+label into one pass. Requires the real-time/local model tier (§6);
  the interface exists from day one so it can be dropped in.

### 5.5 Intent labeling

- A non-destructive annotation pass over an episode's stream range producing a
  semantic label ("navigating to a definition", "reformatting by hand"). Two
  implementations behind one interface: a rules labeler (from markers +
  end-state) and an LLM labeler. Labels enrich episodes for both the bandit's
  features and the future training set.

### 5.6 Tip backends (pluggable generators)

- **Interface**: `generate(context) -> Tip[]` where `context` bundles the
  episode (or coverage gap), the relevant inventory slice, and usage counts.
  `Tip = { id, title, body, suggested_capability, evidence, cadence, source }`.
- **LocalRules**: pattern matchers over episode + inventory. Offline, free,
  deterministic. Handles mechanical and coverage tips.
- **CoverageDiff**: emits "installed but never used" tips from inventory −
  usage, optionally *ordered* by an LLM into a curriculum (§6, periodic tier).
- **LLM (per-episode)**: builds a **redacted** prompt from the episode's stream
  range + inventory slice, calls the configured provider, parses structured
  tips. Redaction strips buffer text down to structural tokens by default.
- **LLM (periodic / session)**: cross-episode pattern mining over the day's
  episodes — habits rules can't see across episodes; and curriculum ordering.

### 5.7 Ranker (contextual bandit)

- **Role**: given candidate tips + a context feature vector (tip source/kind,
  capability, time-of-day, recent-acceptance, episode label), select which — if
  any — to surface, and in what order.
- **Algorithm**: a lightweight contextual bandit (LinUCB-style or
  epsilon-greedy over hashed features) implemented in pure Lua. Online: updates
  on every feedback event. State persisted as JSON.
- **Why not an LLM here**: ranking must be instant, offline, and *learn from
  you live*. That is a bandit's job, not a model's. LLM proposes; bandit
  disposes.

### 5.8 Feedback loop

- **Outcomes**: `acted_on` (the suggested capability is used within a window
  after the tip), `dismissed` (explicit), `ignored` (window elapses, no action).
- **Acted-on detection** reuses the usage resolver: after a tip names capability
  `X`, watch the stream for `X` within T.
- Feeds the bandit reward **and** is persisted as the labeled dataset
  (`stream window + inventory → tip → outcome`) — the pillar-4 dual-use asset
  and the teacher-signal for a future end-to-end model.

### 5.9 Delivery UI

- **Ambient**: when a segmenter fires and the bandit clears a confidence
  threshold, surface *one* tip via a quiet, non-modal channel (a corner
  virtual-text / mini-window), never stealing focus. Hard rate limit +
  do-not-disturb (config: max tips/hour, quiet while in insert mode, etc.).
  Anti-Clippy discipline is a requirement, not a nicety.
- **On-demand**: `:Clippy ask "how do I rename across the project?"` answers
  **against live inventory** — "you have `<leader>cr` bound to that" — not a
  generic vim tutorial. Uses the LLM backend when configured; falls back to an
  inventory search + rules when not.
- Every surfaced tip carries the affordances that produce feedback (act /
  dismiss).

## 6. LLM integration: three cadences + the end-to-end seam

The LLM is not one box; it plugs in at three cadences behind **one `llm`
interface**, with cadence as first-class config (`realtime | per_episode |
periodic`). Any tier can be independently enabled, pointed at a different
model, or A/B'd against a rules baseline.

| Cadence | Frequency | Jobs | Model class | Status |
|---------|-----------|------|-------------|--------|
| **Realtime** | per-event window | LLM segmentation, intent labeling | small/local (the fine-tune/LoRA target) | seam only, first pass |
| **Per-episode** | on episode close | tip generation, pedagogical phrasing | cloud or local | built (BYO key) |
| **Periodic** | session/idle | cross-episode pattern mining, curriculum | strong cloud | built (BYO key) |

**The end-to-end trajectory (explicit, but not built now).** The voice-model
analogy: the old ASR→NLU→TTS pipeline lost information at every handover; the
end-to-end model wins by never compressing. Here, the realtime tier is the
end-to-end target — a single local model that reads the raw stream and emits
intent-tagged tips directly, collapsing segment+label+generate. Two things
never collapse into it: **inventory** (runtime facts, always injected as
context — a model can't hold your keymaps in its weights) and the **feedback
loop** (online personalization stays the bandit's job).

**Why the discrete pipeline now is the runway, not a compromise.** In voice,
the pipeline was how the end-to-end model got bootstrapped: it labeled the
data. Identically here — every `(stream window → tip that landed)` pair the
feedback loop logs is a training example for the eventual local end-to-end
model. Pipeline is the teacher; end-to-end is the student. Building the
observable, debuggable, discrete-stage version first *is* the path to the
ambitious version. LoRA/fine-tuning are downstream of this dataset and out of
scope for the plugin.

## 7. Privacy & redaction

- Default: master-enabled capture, **zero network**. Nothing leaves the machine
  unless an LLM backend is explicitly configured with a key.
- **Redaction layer** sits between episodes and any LLM call: by default,
  buffer text is reduced to structural tokens (motions, mode transitions,
  command names, capability ids), not literal contents. Levels are config
  (`structural | redacted-text | full`), defaulting to the safest.
- On-disk stores contain only what capture recorded; a `:Clippy purge` clears
  them.

## 8. Configuration surface (sketch)

```lua
require("clippy").setup({
  enabled = true,
  capture = { ring_seconds = 120, quiet_in_insert = true },
  segmenters = { "friction" },            -- add "idle", "semantic", "llm"
  backends   = { "rules", "coverage" },   -- add "llm_per_episode", "llm_periodic"
  llm = {
    provider = nil,                        -- nil = fully offline
    cadences = { per_episode = false, periodic = false, realtime = false },
    redaction = "structural",
  },
  delivery = { max_tips_per_hour = 4, do_not_disturb = false },
  ranker = { algo = "linucb", explore = 0.1 },
})
```

## 9. Persistence layout

Under `stdpath("data")/clippy/`:

- `usage.json` — capability counters
- `episodes/` — rolling recent episodes (stream slices + annotations)
- `feedback.jsonl` — append-only outcomes (bandit signal + training set)
- `bandit.json` — ranker state

## 10. Testing strategy

- **Stream/segmenter**: feed synthetic event sequences (recorded or
  hand-authored), assert episode boundaries and markers. Pure functions over an
  event list — no live Neovim needed for the core.
- **Inventory**: run in a headless Neovim with a fixture config; assert
  enumeration against known keymaps/commands.
- **Usage/coverage**: given a stream + inventory fixture, assert counters and
  the inventory−usage diff.
- **Bandit**: simulate feedback streams, assert convergence toward
  higher-reward arms; deterministic with a seeded explore.
- **Backends**: rules backends are unit-tested directly; LLM backends are
  tested against a mock provider returning canned structured tips, so no
  network in CI.
- **Redaction**: golden tests that a given episode never emits literal buffer
  text at `structural` level.

## 11. Build order (informative)

Not a spec constraint, but the intended path so the harness exists before the
ambition:

1. Event stream + ring + usage counters + inventory enumeration.
2. Coverage-diff backend + a minimal on-demand `:Clippy ask` over inventory —
   first visible value, no episodes yet.
3. FrictionSegmenter + LocalRules episode tips + ambient delivery.
4. Feedback loop + contextual bandit.
5. LLM interface + per-episode and periodic cadences (BYO key) + redaction.
6. Designed-for seams exercised: idle/semantic segmenters, LLM segmenter,
   intent labeler — the experiment-harness payoff.

## 12. Explicitly out of scope

- Hosted inference API, subscription billing, cloud dashboard/telemetry.
- Model training, LoRA/fine-tuning (downstream of the feedback dataset).
- Any non-Neovim surface (shell, git, terminal). The stream/backend design is
  generic enough to ingest them later, but they are not built.
