# Templates

Copy these, then cut what doesn't apply. Angle brackets are placeholders.

## Worker brief

```markdown
# Brief: <the job in a few words> (`proto/<name>`)

<One paragraph: what you build or find out, for which project, alone in one
worktree, reporting back to the orchestrator.>

## The request
> <the user's words, quoted; private briefs only>

<The orchestrator's reading: what it means concretely, what it doesn't ask for.>

## Where
- Worktree (work only here): `<repo>/.claude/worktrees/<name>`, branch
  `proto/<name>`, made from `<base branch>` (<commit>). <Why this base.>
- Read first: the instruction file (`AGENTS.md`), then <docs>, <code>.

## Setup
- `<ENGINE>` variable: <hidden launcher path>. Mute runs; logs go to `test_runs/logs/`.
- Import once, then make your looks baseline (both renderers) before changing anything.
- Known traps: <trap 1>; <trap 2>.

## What others are doing
- <job A> changes <files / screen area>: stay out of it.

## Milestones
1. <design note / reproduction> 2. <core> 3. <integration + e2e> 4. <polish, sheets, doc>

## Rules
- Tests and e2e pass at the end. Looks in both renderers: explain every changed
  shot in a line per group; with the new switch off nothing changes.
- New effects: a switch and tuning rows; seeded sessions unchanged.
- Small commits. No push, no merge. Nothing written outside the worktree <except ...>.
- Stop only processes you started, by exact PID. No mouse capture. No downloads.
- A denied permission: don't work around it, say so in the report.

## Budget
Quality first, but work lean: grep before reading, read line ranges, keep
command output short, one contact sheet instead of many shots.
Hand off at a milestone after about 70 tool calls: `test_runs/HANDOFF.md`
(40 lines max), then report and say so. If the note exists, read it first.

## Report (at most 300 words, plus paths)
- what it does and how it's built (a line each); decisions and why
- test / e2e / looks / bench results; the sheets to look at
- open questions for the user; known gaps; anything denied
- the launch command

## Review notes from the orchestrator
<appended after each handoff or review round>
```

## Handoff note (`test_runs/HANDOFF.md`, at most 40 lines)

```markdown
# Handoff: <job>, after milestone <n> (<date>, <n> tool calls)
Done: <milestone> — <commit> <one line>; <commit> <one line>
Decisions: <what and why, one line each>
Files: <main files touched>
Check: <commands that prove it works; expected results>
Next: <the next milestone, concretely, in order>
Traps: <what cost time; what not to touch>
Open questions for the user: <if any>
```

## Worker report

```markdown
<Job> done (or: handed off after milestone <n>). Branch proto/<name>, tip <commit>, <n> commits.
- Built: <feature>, behind switch <where> (default <on/off>).
- Checks: tests <n> passed; e2e <n>/<n>; looks <identical / n changed, why>; bench <numbers>.
- Look at: <path to the key sheet>.
- Open: <questions for the user>, <known gaps>.
- Denied / left alone: <permission denials, stray processes with PIDs>.
- Launch: <command>
```

## Orchestrator review checklist

- [ ] Diff stats: files and lines changed, where the code went (pure rules vs scene glue).
- [ ] Nothing outside the worktree changed; no stray generated or reformatted files (revert them).
- [ ] The key sheet looked at: the feature reads as asked, and nothing in the showpiece is spoiled.
- [ ] My own background run: unit tests (count), looks in both renderers (identical, or changes explained).
- [ ] Risky parts read: pure rules, threads, anything that touches the user's files or opens a port.
- [ ] The new behaviour is behind a switch with tuning rows; seeded sessions unchanged.
- [ ] The instruction file is updated for whatever a later agent must know.
- [ ] Then push `proto/<name>`, update the records, and report to the user. Or send back with numbered points.

## Check-in prompt (scheduled every 30 minutes while workers run)

```text
Check-in while workers run; the running-jobs file says who. Keep it short; if
nothing changed since the last check-in, stay silent.
1) Read the usage meter. At or above the floor (say 98%): stop the workers,
   log where each stands, tell the user in two lines.
2) Context of each worker: past ~250k, ask it to hand off at its next milestone.
3) A worker that handed off: review the milestone, append review notes to the
   brief, stop its task, start a fresh worker of the same type on brief + note.
4) A worker stopped by a limit: resume it if its context is small and warm,
   else a fresh worker from git and the note.
5) A worker that reported: review, push, report to the user.
6) Nothing running: delete this timer.
```

## Report to the user (one block per prototype)

````markdown
**<Prototype name>**: <what it does, in one or two plain sentences>.
Try: <what to do, with keys: `C` turns chipping on, `T` opens tuning>.
Open questions: <one line each>.

```
<engine-exe> --path <repo>/.claude/worktrees/<name>
```
````

Rules: one launch command per code block, in the user's shell (forward slashes worked in both PowerShell and bash). Link files, don't attach them. Say which build is newest and complete. Say what is untried by hand ("everything scripted, nothing played").
