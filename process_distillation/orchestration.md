# Orchestration and subagents

How the main session ran about 90 worker jobs over six days. The mechanics below are Claude Code's (the Agent tool, `.claude/agents/*.md`, scheduled prompts). The ideas carry over to any product: `agent-agnostic.md` says how to run the same thing without subagents.

## Roles

| Role | Does | Never does |
|---|---|---|
| **Orchestrator** (the main session) | Splits requests, picks bases, makes worktrees, writes briefs, starts workers, keeps the log, does light reviews, pushes `proto/*` branches, reports to the user, records decisions | Deep work itself; long command output; reading whole diffs; merging into `main` without the user's word |
| **Builder** | Builds one feature to a clear specification in its worktree | Push, merge, touch other worktrees or the main checkout, wander outside its feature |
| **Researcher / designer** | Open questions: design notes, market or naming research, critical strategy, visual options with sheets | Same limits; it reports sources and says what is a guess |
| **Consolidator** | Merges several prototype branches into a new build in its own worktree, resolves conflicts, checks the whole, documents what each brought | Change the branches it merges |
| **Mechanic** | Scripts, data crunching, mechanical edits with a precise spec | Judgement calls on look, feel or design |

## Model and effort (what we settled on)

- **High effort on the strongest model** for anything needing ideas, design, or an eye for the look. That includes dashboards and pages that must look good, game feel, rules, consolidation.
- **Medium effort on the strongest model** for a build with a clear specification.
- **The cheaper model** only for mechanical, well-specified work. The user rejected it for visual work: quality comes first even when saving quota. In our measurement it saved less than expected, because most of the cost is re-reading context, not output.
- **Maximum effort** only when the user asks for the deepest work (loop research, the strategy proposal, the dashboard).
- **Never a generic built-in worker type** that inherits the main session's settings. Ours silently ran at maximum effort.
- Worker definitions (`.claude/agents/<name>.md`: model, effort, a short system prompt with the rules and the handoff paragraph) are in git. **Probe a new or edited definition** with a one-turn job before relying on it. Early on, new definitions needed a restart (two failed launches), and one failed three times before it loaded. Edits sometimes didn't reload mid-session.

## Briefs

The worker's prompt is one line: *"Your brief is the file `<path>`: read it first and follow it."* The brief is a file so it can be re-read, appended to, and given to a successor. The template is in `templates.md`. What made briefs work:

- **The request in the user's words**, quoted, plus the orchestrator's reading of it. Quote only into private briefs, never into committed files (see `agent-agnostic.md`).
- **Where:** the worktree path, the branch and its base commit, and which docs and code to read first. Point to them, don't retype them.
- **Known traps**, learned by earlier workers. For example: an import step adds a stray line to a resource file, so revert it; a shot tool needs a longer settle time for big stacks.
- **What others are doing in parallel**, and which files or screen areas to stay out of.
- **Milestones**, each a natural handoff point.
- **How to check:** which tests, end-to-end scenes, looks runs in which renderers, which sheets to make. Every changed screenshot is explained in a line per group.
- **Rules:** no push, no merge, no writes outside the worktree (named exceptions only), no stopping processes not your own, no downloads. A denied permission is reported, never worked around.
- **A budget block:** grep before reading, reading by line ranges, short command output, one contact sheet instead of many shots, a report of at most 250 to 300 words.
- **The report's contents**, with the launch command.
- **Review notes**, appended under a heading after each handoff or review round, so the successor knows what is settled and what to fix.

## Handoffs (essential)

Each turn re-reads the whole context. Measured on one day: about 73% of the cost was carrying context, and agents that ran on reached 500k to 840k tokens.

- A worker hands off **at a milestone** (a part done and committed, never in the middle of a problem) once it has made **about 70 tool calls**, or once its context passes **about 250k tokens** (the orchestrator checks this and asks).
- The note: **at most 40 lines**, covering what's done (with commits), decisions and why, files touched, how to check, what's next, and traps. In the worktree at a fixed path (`test_runs/HANDOFF.md`).
- The orchestrator reviews the milestone, appends review notes to the brief, **stops the finished worker's task** (so it can't wake up and write into the shared worktree), and starts a fresh worker of the same type: its prompt names the brief and says to start from the handoff note.
- In practice, workers ran 70 to 140 tool calls and ended at 130k to 330k tokens. The fire-loop prototype took five workers in a row, and the successors did fine from the notes.
- **Within an hour** (the cache lifetime) a fix round can resume the same worker. After that, start a fresh one from the note: resuming a cold large context costs a full re-write.
- **Under a quota cut-off**, workers are told so: commit every working step and keep the note current from the start. When the quota ran out mid-run and the conversation came back under a new session id, the old workers could not be resumed at all. Git and the notes were all that survived.

## Check-ins

While workers run, a scheduled prompt fires every half hour (minutes 13 and 43). It:
1. reads the plan's usage meter, and stops workers near the hard limit (keep a reserve so the user can still chat);
2. reads each worker's context size from its transcript (a small script);
3. asks workers past the threshold to hand off at their next milestone, and starts successors for workers that handed off;
4. continues workers stopped by a limit;
5. deletes itself when nothing runs.

It writes nothing to the user when nothing changed. These timers were **session-only**: they vanished when the session ended, and they couldn't run while the quota was out. Keep the list of running jobs in a file, so any session can pick it up (see `agent-agnostic.md`).

## Parallel work without collisions

- **One worktree per job**, made by the orchestrator from the right base (`branches.md`). The orchestrator never changes directory into a worktree (it uses `git -C` and subshells). A foreground `cd` moved its working directory for good three times, and new worktrees then nested inside other worktrees.
- **Shared screen, shared files:** give each visual job its own region, and tell each job what the others touch. Two jobs that both reorganised the same tuning file conflicted textually. A single central scene script (`chop.gd`, thousands of lines) was the hot spot for every merge, so prefer hooks and components that new features plug into.
- **Chain instead of merge** when work depends on unmerged work: branch the new job from the branch it builds on, and record the chain (`chip-wood → free-chop → shape-score → grade-juice`).
- **Separate scratch folders per job.** One worker overwrote another's helper script in the shared session scratch folder.
- **Live tools stay untouched:** when the user was using the dashboard served from one worktree, its next feature was built in a second worktree and delivered by fast-forward after its tests passed.
- **Benchmarks only when nothing else loads the GPU.** Tests and deterministic screenshots don't depend on timing, so they can run in parallel.

## Reviews (kept light)

The orchestrator's review is a gate, not a second implementation. Checklist in `templates.md`. In short: diff stats and where the code went; the one key sheet; its own background run of the unit tests and the looks check in both renderers; a quick read only of the pure-rule core or anything risky (security of a local helper, threading); then push, or send back with numbered, concrete points. Typical send-backs: an effect that spoils the showpiece; text overlapping a sign on some trees; a feature that is "not good enough in the user's own view" when compared with the user's screenshot; a constant that should be a tuning row.

## Quota (what we measured)

- The plan has a weekly cap and a 5-hour window. One session used 78% of a week: 66% of the week went to its 44 subagents and 12 to 15% to the main thread.
- **Carrying context was 73%** of the cost. **Cold caches were 24%**: subagent prompt caches lasted 5 minutes by default, and pauses inside runs (long commands, waits) forced full re-writes. Setting the subagent cache to 1 hour fixed most of that (a per-machine setting).
- A worker's fixed start was about 46k tokens with all tools. A tool allowlist would have halved it, but the user judged the saving (under 2% of a week) not worth the risk of a missing tool.
- When the user is done for the day with quota left, use it: start the queued jobs, tell the workers they'll be cut off, and continue after the reset (a one-shot timer plus the check-in as a backup).
- A small usage tool (reference: `tools/usage/` on `proto/usage-report`) reads the transcripts and prices them, calibrated against the plan meter. Run it once early in a project to learn where the cost goes.
