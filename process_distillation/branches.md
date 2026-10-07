# Branches, worktrees and prototypes

## Naming

| Branch | Meaning |
|---|---|
| `main` | What the user approved. Always playable. Tagged at milestones (`m0-graybox`, `m1.4-smashed-set`, ...). |
| `proto/<feature>` | One worker's job: a prototype, a doc, a tool. Pushed after review, so it survives the machine. |
| `proto/combined-<n>` | A combined build: several prototypes merged by a consolidator. The newest complete one is "where to start". |
| `proto/<build-name>` | A named build with a purpose (`proto/core-loop`: everything for settling the core loop, minus side areas). |

Name branches for what they are, not for the agent (`proto/chip-slivers`, not `worktree-agent-ab12...`). The product's automatic worktree branches were renamed to readable `proto/*` names before pushing.

## Worktrees

- One per job, under `<repo>/.claude/worktrees/<name>/` (any ignored folder works).
- **Made by the orchestrator, from the branch that fits:**
  ```bash
  git -C <repo> worktree add .claude/worktrees/<name> -b proto/<name> origin/<base-branch>
  git -C <repo>/.claude/worktrees/<name> branch --unset-upstream   # don't track the base
  ```
  The product's automatic worktree option started from the last *push* of `main` (`origin/main`), not the local `main`, and only from `main`. So a job needing another base got a hand-made worktree, and the worker was told to work only there.
- A fresh worktree lacks every ignored folder: the engine's import cache, test baselines, logs. The instruction file has a "worktree sessions" section: set the engine path, run the import once, make your own looks baseline before changing anything. Irreplaceable references (old renderer shots, the benchmark history) stay in the main checkout, read-only.
- The orchestrator **never `cd`s into a worktree** in the foreground. Use `git -C <path>` and `(cd <path> && ...)` subshells.
- Worktrees pile up (we had 69). Clean up only with the user's word, since some are live (a served dashboard, a build the user plays).

## Launching prototypes (essential)

Every prototype launches straight from its worktree and shows its feature without setup:

```bash
<engine-exe> --path <repo>/.claude/worktrees/<name>
```

- New behaviour is on by default *in its branch* (or one key away, and the report says which key). The old behaviour stays as a switch.
- Dev keys stand in for long setups: `G` grants gold, `P` stacks 25 Perfect discs, `1/2/3` jumps to a layer, `Shift+N` restarts. They're listed in the report.
- A prototype that is a page or a tool gets its own one-line start command.

## Base choice and chaining

- **Branch from what the user plays**, so the prototype contains every earlier improvement. For a new loop, the base was "the newest build of the line the user plays", even though no branch had everything.
- **Chain work that builds on unmerged work**, and record it: `chip-cuts-3 → chip-wood (+ wood-3d) → free-chop → shape-score → grade-juice`, with `chip-slivers` and `hold-wood` hanging off `free-chop`. One `git branch --contains` query tells which branches are leaves (the things left to try).
- **Branch for a clean later merge:** when a feature will be merged into a sibling's branch, start it from that sibling's newest commit. For example, the bug-report feature started from the A/B branch, so the final merge of A/B's late fixes was trivial.
- **New work goes on new branches**, so earlier results stay playable side by side. Round 4's rule was strict improvements, or new prototypes that leave the originals alone.

## Combined builds

A consolidator worker (high effort, own worktree) merges the chosen branches one at a time onto a base. After each merge it runs tests and looks, then checks where features meet (two features writing the same state, sounds per hit, camera framing), updates the instruction file, and produces one sheet in both renderers. We made `combined` to `combined-6`, then `core-loop`.

- Typical cost: one high-effort worker per build, sometimes with a fix round. Conflicts clustered in the central scene script and in tuning files that two features both reorganised.
- **Leave out on purpose** what the user hasn't approved (seasons waited for a yes; the village, block and yard were taken out of the core-loop build). Write down what was left out and where it still lives.
- Never let the consolidator change the branches it merges.

## `main` must not drift (lesson)

We merged nothing into `main` for six days while building on `proto/*`. By then the newest build was 371 commits ahead, with an instruction file about 60 lines newer. Every worker auto-loaded `main`'s stale instruction file first and then read its branch's newer one. Tools built on side branches (the hidden launcher) were referenced by absolute paths into other worktrees.

Next time:
- After the user tries a build and says yes, merge **that build** into `main` and tag it. Don't merge every prototype branch.
- Merge tools and instruction-file changes to `main` early: they carry no game risk.
- Start new workers from `main` whenever it is current.
- Push `main`, the branches and the tags after each merge, so every machine and every worker sees them.

## Engine and editor traps around branches (Godot-specific, general idea: generated files)

- An open editor keeps its own copy of the project settings and writes it back on save, overwriting edits made on disk. Ask the user to close the editor before changing project settings.
- Switching branches with the editor open made it delete the generated `.uid` and `.import` files of anything missing on the other branch. After switching back or merging, check `git status` and restore them (`git checkout -- .`).
- The engine rewrote an export-presets file in its new format on its own. Explain such diffs to the user and let them decide; don't commit them silently.
- Adding a class or changing an imported asset needs an import run (headless, a few seconds), or headless runs fail with "identifier not declared". The instruction file says so.
- A resource whose type changes needs a new file name: caches keep the old type.
