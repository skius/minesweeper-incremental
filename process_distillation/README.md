# Process distillation: how we built Logremental with agents

This folder is what we learned while building **Logremental**, a 3D incremental game about chopping logs (Godot 4.7, 2026-09-26 to 2026-10-05). In those ten days, one person and a coding agent (Claude Code: a main session plus about 90 subagent jobs) wrote some 500 commits on the newest line and pushed 65 prototype branches. Along the way we worked out a process. Some of it worked very well, and some of it cost us.

It's written for **a fresh agent at the start of a new project**. The user will copy this folder in, or point you at it, and say, roughly: "this is how we worked before; use the good ideas here too". The folder stands alone. You don't need the Logremental repo or the old conversations to act on it.

## How to use it (for the agent)

1. Read this page, then [`workflow.md`](workflow.md) and [`working-with-the-user.md`](working-with-the-user.md). They're short, and they hold the habits the user expects from the first day.
2. Before the project has more than a few files, set up the skeleton in [`agent-agnostic.md`](agent-agnostic.md): one instruction file (`AGENTS.md`), process state in the repo, tools as plain scripts, a bootstrap script. Retrofitting it later was the expensive part.
3. Build the testing harness in [`testing.md`](testing.md) **with** the first feature, not after it. Seeded, scripted play, plus screenshot comparison, is what let agents change things safely.
4. Add the feedback loops in [`feedback-loops.md`](feedback-loops.md) once there is something to play: tuning panels first, then the in-game report button.
5. Read [`lessons.md`](lessons.md) before you scale up to parallel agents. Most of it is about what parallelism costs.
6. Adapt; don't copy blindly. Godot, Windows and Claude Code specifics are marked as such, and each comes with the general idea behind it. Ask the user before you adopt the heavier parts (the dashboard, A/B tuning).

**Essential** marks what we would set up again on day one. **Nice to have** marks what paid off later, or only at scale.

## The practices that mattered most

1. **The user tries everything before it merges.** Every result is a branch that launches with one command. Nothing reaches `main` until the user has played it and said yes. *Why:* the user is the judge of feel, and scripted checks can't be.
2. **One instruction file, kept current, on `main`.** Conventions, tools, traps and rules live in the repo's instruction file, and every agent reads it first. *Why:* a fresh agent with a good instruction file needs no history. When `main` drifted, agents read stale rules.
3. **Deterministic, scripted play.** Fixed time step, seeded random numbers and one driver feeding input are shared by the end-to-end tests, the benchmark and the screenshot check. *Why:* the same code gives identical frames, so any change shows, including accidental ones.
4. **Look at the game, constantly.** Agents take screenshots, film motion as strips, and build contact sheets and before/after sheets. Reviews look at the sheet. *Why:* most bugs in a game are visible, not logical.
5. **Pure rules apart from scenes.** Rules (geometry, grading, scoring) live in node-free code with fast headless tests. *Why:* those tests run in seconds and in parallel worktrees.
6. **Every effect switchable and tunable; saves never overwrite assets.** Tuning panels write new config files. A disliked effect becomes an off switch rather than being deleted. *Why:* the user decides by playing with alternatives, not by reading about them.
7. **The orchestrator only orchestrates.** The main session splits requests, writes briefs, reviews and reports. Workers do the work in their own git worktrees. *Why:* it keeps the main context small, and lets work run in parallel without collisions.
8. **Briefs are files, and so are handoffs.** A worker gets a one-line prompt pointing to its brief. It hands off with a note of at most 40 lines after about 70 tool calls, at a milestone. *Why:* about three quarters of the measured cost was agents re-reading long contexts. Files also survive crashes, quota cut-offs and session changes.
9. **A report button in the game.** One key captures the screenshot, the marked areas, the build, the game state and the log tail. Agents answer in the report's folder. *Why:* playtest feedback arrives complete and reproducible, without the user describing setups in chat.
10. **Engine errors are test failures.** Loggers count engine and script errors during tests. *Why:* the physics engine silently refused shapes, and pieces fell through the floor for days until the user pasted a log.
11. **Respect the user's machine.** Test windows run hidden, runs are muted, and logs go to the test folder. Never stop processes by name, never capture the mouse, never download anything without asking. *Why:* the user works on the same computer while agents run.
12. **Decisions get recorded, and decided.** Each open decision is a card with stills, options and the user's pick. *Why:* without it, options pile up faster than they're tried: our biggest failure (see `lessons.md`).
13. **Commit small, checkpoint at feature ends, keep going.** Tick the task list, commit, push, and carry on with the next task without stopping to ask. *Why:* long autonomous runs lose nothing when a context is summarised or cut off.

## Map

| File | What it holds |
|---|---|
| [`workflow.md`](workflow.md) | The loop from a request to a merge: who does what, and how the user stays in it |
| [`orchestration.md`](orchestration.md) | Subagents: roles, model and effort, briefs, handoffs, check-ins, parallel work, reviews, quota |
| [`templates.md`](templates.md) | Copy-ready brief, handoff note, worker report, review checklist, check-in prompt, report to the user |
| [`branches.md`](branches.md) | Branch naming, worktrees, launching prototypes, combined builds, keeping `main` current |
| [`testing.md`](testing.md) | Unit tests, scripted end-to-end play, screenshot comparison, benchmark, shot tools, quiet and hidden runs |
| [`feedback-loops.md`](feedback-loops.md) | The in-game report button, A/B tuning, tuning panels, the decisions page, the session dashboard |
| [`working-with-the-user.md`](working-with-the-user.md) | The user's lasting preferences, generalised, with this game as the example |
| [`agent-agnostic.md`](agent-agnostic.md) | How to set up the next project so that any agent product can pick it up from the repo alone |
| [`lessons.md`](lessons.md) | What didn't work, why, and the fix we found or would choose next time |

## Further reading (optional)

The reference implementation is the private repo `git@github.com:skius/logremental.git`. The newest line is the branch `proto/hull-fix` and its successors. Its `CLAUDE.md` is the full instruction file this folder generalises. Other branches are named in each file where they help. Nothing here depends on them.
