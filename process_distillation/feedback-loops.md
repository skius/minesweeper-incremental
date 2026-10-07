# Feedback loops with the player

The user plays, the agents fix. These tools turned "it feels off somewhere" into something an agent can act on without a long chat. In order of value per effort: tuning panels, the in-game report, the decisions page, A/B tuning, the session dashboard.

## 1. Tuning panels whose saves never overwrite assets (essential)

- **What:** every tunable number is an exported field with a range hint, on resources registered as sections of one tuning set. In the game, one key opens the gameplay panel and another the look panel. Rows are built from the fields, with a hover text from each field's doc comment.
- **Saves:** every save writes a **new** config file to `configs/` (in git). Configs can be loaded back. One can be marked to load at start. "Defaults" returns to the asset values. Tests and shot tools always start from the defaults. A default changes for good only by editing the asset, after the user picks a config they like.
- **Why it helped:** the user tunes while playing and keeps every experiment. Agents get exact numbers instead of adjectives. Disliked effects become off switches here (see `working-with-the-user.md`).
- **Grows into a navigation problem:** at about 200 settings the panels were too convoluted. The rework was a map of categories with search, recent items, small pop-out windows that can be dragged and stacked, and gold dots on changed values (click to reset). Plan for a hierarchy early.
- **Look settings as distributions:** per-tree looks are a fixed value or a min/max with a density, drawn once per tree from a hash of the tree's number and the setting's name. Mix seeds with an array hash, not a formatted string: string hashes of consecutive numbers moved in lockstep.

## 2. The in-game report button, F10 (essential once someone plays)

**Capture (one key, anywhere):**
- the frame as it was, before the dialog draws;
- the game pauses; the player drags rectangles on the picture to mark areas (Undo / Ctrl+Z), types what happened, and saves with Ctrl+Enter. Esc cancels but keeps the words for next time. Nothing reaches the game while the dialog is open.

**The report folder** `<user-data>/bug_reports/<local-stamp>/`:
- `<stamp>_user_highlighted_area.png` (`_2`, `_3`...): each marked area cropped, *the first thing an agent looks at*;
- `<stamp>_full.png`, plus `<stamp>_marked.png` with the outlines;
- `report.md`: the words; each area's pixel coordinates; the build (branch, commit, uncommitted changes, which worktree); the game state (scene, view, tree number, phase, last cut, the config loaded and every tuning value off its default, the A/B pair); the machine (engine, renderer, GPU, window, frame time); the last 40 game events (cuts with grades, topples, sales...); a debug state dump; the last 80 lines of the run's own log.
- One `index.md` line per report at the top of the folder, and a `README.md` the game rewrites at every save, explaining the layout and the answer convention to any agent on any branch.

**Answers** (agreed with the user):
- not every report is a bug; some are a confused player;
- agents write `answers/<YYYY-MM-DD_HH-MM-SS>_<author>.md`: header lines `status:` (answered, not-a-bug, needs-info, planned, fixed with `fix: <branch> @ <commit>`, duplicate with `of:`), `by:` and `about:`, then plain sentences for the player;
- append-only; agents never touch the player's own files. A report's status is its newest answer's, and `new` when it has none;
- a small listing tool shows open reports. Agents answer **only when the user asks** for reports to be gone through.

**Past reports in the game:** a button in the dialog (gold, with the count of unread answers) lists every report. Answered rows are solid cards with a status chip; unanswered rows are flat and muted; unread answers get a dot. A detail view shows the words, the crops (click for the full shot), the build and every answer. Read marks live in the game's own file in the reports folder, which follows the test override, so tests never mark the user's answers read.

**Build stamp:** the branch and commit come from reading the `.git` files directly (a worktree's `.git` file is followed to the shared refs). An exported build has no `.git`, so the export writes a small stamp file.

**Why it helped:** in one evening the user filed six reports. One worker (through two handoffs) fixed all six with one commit, a test and a before/after sheet each, and answered each report. Later reports pointed straight at the hull bug.

**Essentials to rebuild:** a global autoload or singleton; screenshot before the UI; crops; state from a "report source" interface any scene can implement; the log tail from the run's own log; the folder outside the repo but shared by all branches; the README convention; the answers folder; a reader with tests and fixtures. Reference: `game/bug_report/`, `game/core/bug_reports.gd`, `tools/bug_reports.gd` on `proto/hull-fix`.

## 3. A/B tuning mode (nice to have; strong for settling feel)

- **What:** the player plays two variants of the tuning, flips between them live (Tab), and picks one (Pick A, Pick B or Space for the side in play; Backspace undoes for a few seconds), optionally with words. An **algorithm, not an agent,** makes the next pair.
- **The search:** settings are normalised to 0..1 through their range hints (log for exponential ones). Each pair moves at most two settings of one group, or one switch, so the difference is something the player can feel. Pairs are antithetic around the current best (best ± d, sides shuffled). Step sizes follow sign-only answers (Rprop): grow by 1.3 when a setting wins the same way again, halve on a reversal; "can't tell" grows the step once and lowers that setting's interest. The best is always a variant the player actually chose, never a model's blend. The state is a fold over the stored answers, so it survives restarts and can be replayed in tests with a simulated player who has a hidden favourite.
- **Freezing:** locks in the tuning windows freeze a section, a group or a setting. Looks, menus, music and debug settings are frozen or locked by default.
- **Storage (in git):** `ab_tuning/<run>/start.cfg` plus one file per answer: the pick, how it was made, the feedback, the settings moved with both values, the time and the discs cut on each side, the commit, the freeze rules. "Load A/B best" applies the winners without overwriting any config.
- **Privacy rule:** the player's feedback text is read by an agent only when the user asks.
- Reference: `docs/game-design-doc/ab-tuning.md` on `proto/ab-tuning`.

## 4. The decisions page ("picks page")

- **What:** one card per open decision, in the order the player meets it in the game: what was built, how to try it, stills, options, and a free note. The user clicks a pick, and the page stores it in a small database the orchestrator reads before merging. Picks given in chat are written there too, marked as from chat. It grew to more than 80 cards.
- **Why it helped:** the user could go through decisions on a phone, away from the desk, and the orchestrator always had the current picks.
- **What didn't:** it lived on the agent vendor's hosting, outside the repo. Most cards stayed open, because options came faster than decisions (`lessons.md`). Next time: `work/decisions.md` in git (or one file per decision), rendered by a local page if wanted, and a rule that a tried result gets a decision within two days or is parked.

## 5. The session dashboard (nice to have, at scale only)

- **What:** a local web page plus a small Python helper that maps a whole orchestration session as a graph. Messages are split into readings, then come jobs, results, builds, decisions and parked ideas. Three arrangements: by topic, as a story, on a timeline. A prototypes view, drawn top-down from git, shows the leaves still to try, each with a button that starts it and a tick to mark it done, and open questions where they were raised. A requests view lists every message and where each part stands. Back and Forward work like a browser.
- **Build essentials:** an extractor reads transcripts and git. A hand-kept graph file holds the understanding: node types `message, reading, agent, work, result, build, decision, idea`, and edges `split, asked, started, made, raises, feedback, answers, built_on, merged_into`. The helper listens on 127.0.0.1 only, checks the Host header and a token, allows path roots and command ids from the graph, and has a dry-run mode. All data stays out of git.
- **Cost:** the orchestrator updated the graph after every request and report, which took tokens and attention. The strategy review called the dashboard a symptom of too much work in flight. Generating it from committed `work/` files would make it free. Reference: `tools/dashboard/README.md` on `proto/dashboard`.

## 6. Playtests with other people (not done; the main gap)

There was one judge, the person who asked for the features. The strategy review's first recommendation was one playable slice, a play log, and sessions with 6 and then 10 to 15 strangers before more branches. Plan this loop from the start in the next project: an exported build, the report button, and a short questionnaire.
