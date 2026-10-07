# What didn't work, and why

Ordered by cost. Each entry gives what happened, why, and the fix we found or would choose next time.

## Process

**1. Options outpaced decisions.** In ten days we pushed 65 prototype branches and merged none of them into `main` after the subagents started. The decision cards numbered 87, 58 of them open. We polished parts whose place wasn't settled: four SELL signs, five grade presets, several menu styles, seven fonts, 20 season-and-hour looks. One system (chipping) took about a third of all subagent calls. Nobody but the requester played anything.
*Why:* parallel agents make options cheap, and trying them isn't cheap. Every result needs the user's time.
*Next time:* at most two prototypes in flight. A tried result gets a decision within 48 hours, or it's parked. No polish branch until a playtest keeps the feature. One build on `main` that the user and testers play. Every brief names the goal it serves; a brief that serves none waits. (From the project's own strategy review, `docs/strategy/proposal.md` on `proto/strategy`.)

**2. `main` drifted 371 commits behind the newest build.** Workers auto-loaded `main`'s stale instruction file, then read their branch's newer one. Tools lived on side branches and were referenced by absolute paths into other worktrees.
*Next time:* merge the approved build into `main` regularly. Merge instruction and tool changes at once. See `branches.md`.

**3. Merging was expensive.** Six combined builds plus a core-loop build, each a high-effort worker run. Conflicts clustered in one large central scene script and in tuning files that two features both reorganised. One merge stopped on a denied permission and waited for the user.
*Next time:* fewer branches in flight (1); features plug into the scene through components or hooks rather than growing one file; branch from the parent a later merge needs; integrate a build every few jobs rather than after a round of eight.

**4. Context blowups ate the quota.** Agents ran to 500k–840k tokens. Carrying context was 73% of the cost, and cold caches 24% (5-minute subagent caches, plus long pauses inside runs). One session used 78% of a weekly quota.
*Fix:* handoffs at milestones (about 70 tool calls or 250k tokens), a 1-hour subagent cache, lean briefs with a budget block, quiet tools, contact sheets. See `orchestration.md`.
*Also seen:* a worker that ended its turn while its own long check ran in the background, a full end-to-end pass of about 15 minutes, was woken a dozen times. Each wake re-read its context of about 210k tokens, only to wait again. If there is nothing else to do, run the check in the foreground with a timeout, or wait for one notification at its end.

**5. Quota cut-offs mid-run, then a new session.** Workers stopped mid-edit. Within one session they could be resumed. When the conversation came back under a new session id, none could be resumed, and the session-only timers were gone. Successors restarted from git, uncommitted files and the notes. Two agents had no note at all.
*Fix:* tell workers when a cut-off is near; commit every working step; write the note from the start. Next time also: the running-jobs list and the notes in git (`agent-agnostic.md`).

**6. State scattered outside the repo:** briefs and the log in a temp folder, preferences in the product's memory, decisions on hosted pages, notes in ignored folders, timers in the session. A move to another product or machine would have lost the process.
*Fix:* `agent-agnostic.md`.

**7. The orchestrator's working directory drifted.** Three times a foreground `cd` into a worktree moved the main session's directory for good. New worktrees then nested inside other worktrees, and a new worker definition didn't load from there.
*Fix:* never `cd` in the orchestrator. Use `git -C` and subshells.

**8. Agent definitions didn't load when expected.** New definitions first needed a restart (two failed launches), one failed three times before it loaded, and edits to an existing definition didn't reload mid-session. A generic built-in worker type silently inherited the main session's maximum effort.
*Fix:* probe each new or changed definition with a one-turn job. Always name an explicit role.

**9. Shared scratch space.** One worker overwrote another's helper script in the shared session scratch folder.
*Fix:* a scratch folder per job, inside its worktree's ignored folder.

**10. Dashboard upkeep by hand.** The orchestrator updated a session graph after every request and report. It was useful to the user, but it cost tokens, and it existed because there was too much in flight.
*Fix:* fewer jobs in flight; generate any map from committed files.

## The user's machine

**11. Windows took the user's focus, and test runs played sound** while the user worked and watched videos.
*Fix:* a hidden launcher (a separate Windows desktop), muted runs, and both set in every brief from then on.

**12. Tool runs pushed out the user's logs.** The engine keeps five logs in the player's folder, and every agent run wrote there. The in-game report then attached the tail of a tool run's log instead of the game's.
*Fix:* each run logs into the test folder (`--log-file`); the reporter reads its own run's log.

**13. A process killed by name.** A by-name kill with a window-title filter sent close requests to the user's open editors.
*Fix:* never by name. Stop only your own processes, by exact PID. When even that was denied, the stray process was left alone and the user got the exact command.

## Engine and determinism

**14. The physics engine silently refused collision hulls.** Thin or near-degenerate generated pieces had their convex hulls refused, so pieces fell through the floor. It was only found when the user pasted the warnings from the log.
*Fix:* hand the engine welded, deduplicated hull points; a logger that counts refused hulls in tests; a drop test asserting zero. In general: **engine warnings must fail tests**, and agents should read the log of every run they look at.

**15. Determinism broke three ways:** a new particle node seeded itself from the global random stream; a feature's own sound stream plus one more physics body shifted the solver order; a real-time hitstop under machine load.
*Fix:* a stream per feature, frame-based time in scripted runs, prewarm copies that don't touch the global stream. Rebaseline on purpose and explain each changed shot.

**16. An open editor overwrote project settings, and branch switches deleted generated files.** The editor writes back its own copy of the settings, and deletes `.uid` and `.import` files of assets missing on the other branch.
*Fix:* ask the user to close the editor before changing settings; after switching or merging, check `git status` and restore.

**17. A baseline older than a renderer switch** made every screenshot "changed" and confused the review.
*Fix:* baselines stamped with commit and renderer; one baseline per renderer.

**18. Flaky end-to-end scenes under load:** one scene failed about one run in five when other windows loaded the GPU.
*Fix:* record it as a known flake, with its own job later; never let it hide a real failure.

## Smaller lessons worth keeping

- **Diagnose before blaming the code.** A reported sound delay was the user's Bluetooth headphones. A test tone on a key proved it. Build the diagnostic switch first.
- **Editor integrations age fast.** An editor bridge did real work on day one only, and the command line did everything after. Prefer plain executables.
- **Scripted is not played.** Many results were scripted end to end, and none of them were played by hand. Reports must say so, and a feel question waits for the user.
- **Hosted pages are convenient but vendor-bound.** The decisions page opened on a phone and fed the orchestrator. Keep the data in git, and treat the page as a view.
- **Untracked user data in worktrees:** the user's first A/B answers lay untracked in a worktree until a worker noticed. Design user-made data folders to be committed (as `configs/` and `ab_tuning/` are), and check `git status` for them in reviews.
- **A live tool in a worktree** (the dashboard the user was using) must not be developed in place. Build the change in a second worktree, and deliver it by fast-forward after its tests pass.
- **Timestamps from a wrong clock:** the orchestration log's times ran about an hour fast for a stretch. Take times from the system, not from memory.
