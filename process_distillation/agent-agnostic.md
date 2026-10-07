# Agent-agnostic setup for the next project

**Goal:** a different agent product, or a fresh session of the same one on another machine, can pick the project up from the repo alone. It should know the conventions, the user's preferences, what's running, what was decided and what's next.

## Where state lived in Logremental (the problem)

| Where | What | Problem |
|---|---|---|
| In git | code, scenes, the instruction file (`CLAUDE.md`), worker definitions (`.claude/agents/`), design docs, saved tunings (`configs/`), A/B history | Fine, but docs were scattered over unmerged branches, and `main` was 371 commits stale |
| In the repo, ignored | test baselines and shots, **handoff notes**, the dashboard's graph and notes | Notes lived only in one worktree on one machine |
| The agent product's private folders | session transcripts (1.7 GB), **the agent's memory** (the user's preferences, the project's direction) | Product-specific and machine-local; another product sees none of it |
| The session's temp folder | **briefs, the orchestration log, helper scripts** | The most fragile: lost with a temp clean-up, and tied to one session id |
| Per machine | the engine executable, the subagent cache setting, scheduled check-ins (session-only), a tool referenced by absolute path into another worktree, the game's user data (settings, bug reports, logs) | Undocumented, or documented only in passing |
| The vendor's hosting | the decisions page and its database, published report pages | Outside the repo and tied to one vendor account |

## The design

### 1. One canonical instruction file: `AGENTS.md` (essential)

- `AGENTS.md` at the root holds what `CLAUDE.md` held: project facts, layout, how to run and test, the performance rules, the art pipeline, git rules, worktree rules, orchestration rules. Several agent products read `AGENTS.md` directly. Check each product's docs.
- Product files are **thin pointers**, one or two lines each: `CLAUDE.md` contains `@AGENTS.md` (Claude Code imports it), and the same goes for other products' rule files (Gemini, Copilot, Cursor...). Nothing else goes in them, so they can't drift.
- Keep it on `main` and current: merge instruction changes to `main` the day they're made. Branch-specific notes go in the branch's docs, linked from `AGENTS.md`.
- Size discipline: ours grew to about 87 KB, read on every start by every worker. Keep the always-needed rules in `AGENTS.md` (aim for under about 25 KB), and move reference detail (the bug-report format, the shot tool's parameters, the performance log) into `docs/` files that it links to by topic.

### 2. Process docs and the user's preferences, committed (essential)

```
docs/process/
  workflow.md        the loop, roles, review checklist (from this folder)
  roles.md           worker roles, neutral (below)
  preferences.md     the user's lasting preferences: what the agent's memory held
  machine.md         what must be set up per machine, and how to check it
  templates/         brief.md, handoff.md, report.md, checkin.md
```

**Memory becomes docs:** whenever the agent learns a lasting preference or a project fact, it writes it, paraphrased, into `preferences.md` or the right doc in the same commit. It doesn't go into a product's private memory. Product memory may hold a pointer to the doc, nothing more.

### 3. Orchestration state in the repo (essential if using workers)

```
work/
  log.md             append-only: date, request (paraphrased), readings, jobs, outcomes, blockers
  jobs.md            the running-jobs list: job, role, branch, worktree, base, started, status, last note
  decisions.md       one entry per open decision: options, recommendation, the user's pick, date
  briefs/<job>.md    each brief, with review notes appended
  parked.md          ideas the user wants remembered, not built
private/             gitignored: the user's verbatim words, transcript digests, raw feedback
```

- **Briefs quote the user only from `private/`.** Committed briefs paraphrase. Run the overlap check (below) in a pre-commit hook.
- **Handoff notes are committed on the job's branch** (`work/handoff/<job>.md`), and the branch is pushed at each handoff, work in progress included. A note in an ignored folder dies with the worktree or the machine.
- **`jobs.md` replaces session-only timers as the source of truth.** Any session, any product, starts by reading it. A check-in, whether a timer, a cron job or simply the start of the next user message, works from it.
- **`decisions.md` replaces the hosted picks page.** A local page can render it and write picks back through a small helper, or the user edits it, or picks come through chat. Either way the result lands in git.
- **A session map, if wanted, is generated** from `work/` and git by a script. It is not hand-kept.

### 4. Worker roles described neutrally

`docs/process/roles.md` defines roles by **capability tier**, not by model name:

| Role | Tier | Effort | Use for |
|---|---|---|---|
| builder | strongest | medium | features with a clear spec |
| designer | strongest | high | ideas, design, look and feel, consolidation, reviews of taste |
| deep researcher | strongest | maximum | only when the user asks for the deepest work |
| mechanic | cheaper | medium | scripts, data crunching, mechanical edits |

Each role has a shared system-prompt paragraph (the rules, the handoff rule, report faithfully). A small script generates the product files from it (`.claude/agents/<role>.md` with model and effort fields; other products' equivalents), so switching products means one new generator, not new prose.

### 5. Tools as plain scripts, the engine from one variable (essential)

- Everything runs from the command line: no editor, no product-specific integration needed. We removed a Godot editor bridge after an audit showed it was useful on day one only; the engine's command line did everything after.
- One file, `tools/env.sh`, sourced by every tool. It reads `.env.local` (gitignored; template `.env.example` in git) for `ENGINE` (the engine path), `HIDDEN=1` (use the hidden launcher), `MUTE=1`, `PYTHON`. It sets the per-run log file and the test data folders.
- The hidden launcher, the log helper, the contact-sheet maker, the usage tool and the report lister all live on `main` from the start. Never reference a tool by an absolute path into another worktree.
- Scripts run in a POSIX shell and in Python with the standard library only. Node only where a headless browser is needed.

### 6. A bootstrap script (essential)

`tools/bootstrap.sh` makes a fresh clone or worktree ready, and says what's missing:
1. Create `.env.local` from `.env.example` if absent, and check `ENGINE` exists and has the right version.
2. Run the engine's import or build step (class cache, assets).
3. Make the looks baselines for this machine (both renderers), stamped with the commit.
4. Run the unit tests once, and print one line.
5. Check `machine.md`'s items (cache setting, hidden launcher works, user-data folder path) and print what's missing.

Workers run it as their first step. The instruction file says so in one line.

### 7. What must stay per machine (document it in `machine.md`)

- The engine executable and its version (path in `.env.local`).
- Test baselines (pixel-exact only on the same GPU, driver and engine).
- The agent product's own settings (in Claude Code: the subagent prompt-cache lifetime of 1 hour in `.claude/settings.local.json`) and its transcripts.
- The game's user data (`%APPDATA%/<game>/`: settings, bug reports, logs). Shared by all branches, which is right for the report button.
- Secrets and accounts (never in git).

For each: what it is, why it can't be in git, the command that checks it.

### 8. When the agent product lacks a feature

| Missing | Do instead |
|---|---|
| **Subagents** | Run the same loop sequentially. One job at a time, still in its own worktree and branch, from a brief file. At each milestone, write the handoff note and **end the session**. The next session starts fresh from `AGENTS.md`, `work/jobs.md`, the brief and the note. A context reset is a free handoff. Parallelism can come from several sessions or terminals, coordinated through `jobs.md`. |
| **Timers / scheduled prompts** | The check-in runs at the start of every session and of each user message: read `jobs.md`, check each branch's last commit and note, and continue what stopped. An OS scheduler (cron, Task Scheduler) can start a headless agent run with the check-in prompt, if the product has a CLI. |
| **Prompt caching** | Contexts cost even more per turn. Hand off earlier (about 40 tool calls, or about 120k tokens), keep briefs shorter, print less, prefer contact sheets. |
| **Memory** | Nothing lost: preferences are already in `docs/process/preferences.md`. |
| **Hosted pages / artifacts** | Local HTML pages generated into an ignored folder, opened from disk or served on 127.0.0.1. |
| **Worker definitions with model and effort** | Put the role's paragraph at the top of the brief, and choose the model when starting the session. |

### 9. The privacy check (essential when committing anything written from a conversation)

A small script compares every committed text file with the user's messages (from `private/`) and fails on any run of eight or more consecutive words they share. Rephrase every hit. No email addresses, no contents of the user's reports or feedback beyond one-line paraphrases, and machine paths as placeholders (`<repo>`, `<engine-exe>`, `%APPDATA%/<game>/`).

## Migration order for an existing project

1. Write `AGENTS.md` from the current instruction file, and make `CLAUDE.md` a pointer. Merge to `main`.
2. Move the memory into `docs/process/preferences.md`.
3. Create `work/` from the orchestration log and the briefs (paraphrased), plus `jobs.md` and `decisions.md` from the hosted page's data.
4. Add `tools/env.sh`, `.env.example` and `tools/bootstrap.sh`. Point every tool at them.
5. Merge the tools living on side branches to `main`.
