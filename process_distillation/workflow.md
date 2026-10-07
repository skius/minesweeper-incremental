# The workflow: from a request to a merge

## Two phases we went through

1. **Single session, milestone branches (days 1 to 4).** One agent session worked straight in the repo. It took one branch per milestone, merged it into `main` when it worked, tagged it (`m0-graybox` ... `m1.10-web`) and pushed. The task list lived in `docs/planning/TASKS.md`. This is the right shape for a small project, or for an agent product without subagents.
2. **Orchestrator plus workers (days 5 to 10).** The main session stopped doing the work itself. It split each request into jobs and gave each job to a subagent in a git worktree of its own. It reviewed what came back and handed the user prototypes to try. Throughput went up a lot, and so did the cost of merging and of deciding (see `lessons.md`).

Start with phase 1, and move to phase 2 when requests start to queue up. Even in phase 1, keep the habits that make phase 2 possible: briefs and notes as files, everything checkable by script, `main` always playable.

## The loop (phase 2)

```
user request ──► orchestrator splits it ──► brief file per job ──► worker in its own worktree
     ▲                                                                   │
     │                                                       commits, sheets, report
     │                                                                   ▼
 decision ◄── user tries the prototype ◄── report to the user ◄── orchestrator review
     │                                                    (fixes go back to the worker)
     ▼
 merge into a build / main (only on the user's word)
```

| Step | Who | What, concretely |
|---|---|---|
| **Request** | user | Often long and dictated, with screenshots, sometimes mid-turn. Several requests in one message are normal. |
| **Record** | orchestrator | Log the request at once (task list or log file), paraphrased, so it survives compaction. Read it into separate *readings*: what each part asks for. A question gets an answer, not a change. Several times the user asked "how would we..." and wanted only the answer. |
| **Split** | orchestrator | Work that touches the same code, or depends on the same design, goes to one worker. Independent features go to separate workers that run in parallel. Each visual job gets its own part of the screen when several change the look. |
| **Pick the base** | orchestrator | Branch from the build the user plays, or from the branch the work extends. If a later merge is planned, branch from the parent that keeps it clean (see `branches.md`). |
| **Brief** | orchestrator | A file with the template in `templates.md`. The worker's prompt is a single line pointing to it. |
| **Work** | worker | Read the instruction file and the brief. Make a looks baseline before changing anything. Commit small. Look at the result (shots, strips, sheets). Run the full checks. Hand off at milestones. |
| **Review** | orchestrator | Kept light: diff stats, the key contact sheet, and its own background rerun of the unit tests and the looks check. Concrete problems go back to the same worker (warm cache, within the hour) or to a successor through "review notes" appended to the brief. |
| **Push and report** | orchestrator | Push the `proto/*` branch. Then one report per prototype for the user: what it does, what to try (keys), open questions, and a launch command in its own code block. |
| **Try** | user | Plays it. Gives feedback in chat, through the in-game report button, through A/B picks, or as picks on the decisions page. |
| **Decide** | user | Keep, change, drop, park. The orchestrator records the decision (decisions page, memory, task list). |
| **Merge** | orchestrator or a consolidator worker | Only when the user says so. Combined builds bring several prototypes together for one try; `main` gets the build the user approved. |

## Keeping the user in the loop without making them babysit

- **Async by default.** The user leaves for hours or for the night, asking for strict improvements or for new prototypes that leave the originals playable. The orchestrator keeps workers going, reviews and pushes, and writes one report for when they're back.
- **One place to start.** Always say which build is newest and complete, and which to try first.
- **Plain words.** No agent ids, no internal names unless the user uses them. Say what the user will see and what to press.
- **Ask before** downloads, installs, merges into `main`, anything that changes the user's machine or accounts, and anything they asked to hear about before it changes.
- **Surface blockers immediately**, in two lines: a denied permission, a stray process the agent may not stop (give the exact command), a decision only the user can make.
- **Answer questions with answers.** When the user asks whether something is possible, answer it, and offer to build. Don't start building.

## Checkpoints

At the end of each feature: tick it in the task list with the details that matter, log any new requests as tasks, commit, merge (if agreed), push. Then go straight on to the next task. Don't stop a multi-task run to suggest compacting the conversation: at most, mention in the final report that it's a good moment. Mid-work requests (a task to add, to start after the current one) go into the task list *immediately*.

## Records the orchestrator keeps

| Record | Purpose | Where it lived | Where it should live (see `agent-agnostic.md`) |
|---|---|---|---|
| Task list | Outstanding requests, ticked as they land | `docs/planning/TASKS.md` (in git) | same |
| Orchestration log | Every request, job, review, outcome, blocker; enough to resume after a crash | session scratch folder (outside the repo) | `work/log.md` in git |
| Briefs | One per job, plus review notes for successors | session scratch folder | `work/briefs/` in git |
| Handoff notes | A successor's starting point | each worktree's ignored `test_runs/` | committed on the job's branch |
| Decisions | Each open decision and the user's pick | a hosted page with a small database | `work/decisions.md` in git |
| Durable preferences | What the user wants, always | the agent product's private memory | `docs/process/preferences.md` in git |
| Session map | Requests → jobs → results → decisions | a local dashboard, data ignored | generated from the files above |
