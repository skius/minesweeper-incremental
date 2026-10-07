# Testing and visual checks

The harness let many agents change a physics-heavy 3D game in parallel without breaking it, and it showed exactly what each change did to the picture. **Build it with the first feature.** Each part below gives the general idea first, then how we did it in Godot (reference paths are on `proto/hull-fix`).

## 1. Pure rules, headless unit tests (essential)

- **Idea:** keep rules (geometry, grading, scoring, layouts, search algorithms) in code with no scene objects, and test it headless in seconds.
- **Here:** `game/core/` (cut geometry, grading, lean, sets, coin heap layout, A/B search, bug-report reader). A small test framework of our own (`tests/framework/`, suites `tests/test_*.gd`), run by `tools/test.sh [suite]`. It grew from about 100 to 530 tests. When the suite slowed down (7 s to 21 s), a worker was told to trim it.
- **Fixtures from real failures:** when the physics engine refused some shapes, the failing point sets were captured into a test that fails before the fix.

## 2. One driver for scripted play (essential)

- **Idea:** a single driver plays the real scene by feeding input events through the scene's own input handler, with live input switched off. End-to-end tests, the benchmark and the screenshot check all use it, so a fix to the driver fixes all three.
- **Here:** `tests/chop_driver.gd` (`ChopDriver`). `tests/chop_session.gd` (`ChopSession`) is one typical session: cuts, a glance, a sale, topples, new trees, an 11-disc streak smashed by the falling tree. The benchmark and the looks check both play it.
- **End-to-end scenes** (`tests/e2e/*.tscn`, run by `tools/e2e.sh`): one per feature area, each with checks and screenshots into `test_runs/`. The script prints one line for the whole run and **exits non-zero** on a failed check, a script error, a crash, a timeout, or a missing summary line. Before that fix, a failing scenario could still exit 0. A hard timeout per scene.
- Scripted runs hand the pointer to the aim guide explicitly. Anything the game normally reads from the live mouse needs a scripted path.

## 3. Determinism (essential)

Everything visual and timed rests on this: **the same code gives the same frames**.
- Fixed game time step (`--fixed-fps 60`), seeded random numbers, a fixed session.
- **Each feature owns its random stream.** Never draw from the global one. A new particle node seeded itself from the global stream and shifted every later draw. A feature's sounds with their own stream, and one more physics body (which changed the solver's order), also moved the seeded sessions.
- **No wall-clock time in scripted runs.** A real-time hitstop made the looks run nondeterministic under machine load. Scripted sessions need frame-based time.
- New features default to **off in the seeded sessions** (or the session pins the old behaviour), so "looks identical with the switch off" is a check every worker runs.

## 4. Looks check: screenshot comparison (essential)

- **Idea:** play the seeded session and save screenshots of fixed moments. Compare them with a baseline made on this machine, and print one line: identical, off by rounding only, or changed. For changed shots, write a compare page.
- **Here:** `tools/looks.sh` takes 40 moments (trees, cut close-ups, the stack and coins, sparks, the sale, falling logs, strikes, crashes, a tall set). "Rounding" means no pixel is off by more than 2/255. Changed shots get side-by-side and zoomed pictures in `test_runs/<stamp>_looks/compare/index.html`. `renderer=both` runs both renderers. `tools/looks.sh baseline` makes a baseline, stamped with its commit (`+` if the checkout was dirty) and renderer.
- **Baselines stay out of git.** Pixel-exact shots only match on the same GPU, driver and engine version. Each machine, and each worktree, makes its own. A worker makes its baseline **before** changing anything (stash, baseline, unstash if needed), so the comparison shows exactly its change.
- **The rule for workers:** look at every changed shot and explain it in one line per group. Nothing changes by accident. The orchestrator reruns it in review.
- Pitfall: a baseline older than a renderer switch made every shot "changed". Stamping fixes the confusion.
- **Matching one look to another** (`tools/looks_match.py`): per-shot numbers (mean difference, brightness of darks, mids and lights, colour). When the project switched renderers, a search tuned fog and light settings to minimise the perceptual colour difference (CIELAB delta E) against the old renderer's shots.

## 5. Benchmark with per-frame data (nice to have, essential for web and phones)

- **Idea:** the seeded session in a real window, frames drawn but not shown (no display cap). Each frame is split into physics, process, render and GPU time, and tagged with the step and the events it happened in (hits, splits, new trees). Three summary lines are printed; everything else goes to files.
- **Here:** `tools/bench.sh [name=<label>]` writes `frames.csv`, `events.txt`, `summary.txt/json` (percentiles, 1% low, spikes, per-step table, slowest frames) and `chart.html`. It adds a row to `test_runs/bench_history.csv`, whose renderer column says which renderer ran. In Forward+ it counts pipelines compiled mid-game. In Compatibility it can't, so look for spikes where something first appears.
- **Prewarming:** anything that first appears mid-game (a material, a mesh format, idle particles, a hidden mesh) gets drawn for two frames at load, inside the trunk. Every new HUD character goes into the warmed glyph list. The bench checks it.
- **Hot paths with digests:** a headless script times the heavy functions (trunk surface, pieces, hulls, splits, roots, layout) for trees 1–5, and prints a digest of what they built. A rewrite must build exactly the same.
- Run it only when nothing else loads the GPU. The performance rules it taught us went into the instruction file (never read meshes back from the GPU in gameplay; no per-triangle loops; split work on threads with plain arrays; merge static scenery into one mesh per material for the Compatibility renderer).

## 6. Shot tools for looking and for option sheets (essential)

- **Idea:** one command makes a 1080p still of any state. Parameters set any look setting, any node property, the tree, the axe position, the view, a played cut sequence, a stack, a coin count. Agents use it to see their work, and to build option sheets for the user.
- **Here:** `tools/shot.sh` (parameters parsed in `tools/shot.gd`):
  - `tree=<n>`, `cuts=0.6,0.75/8`, `stack=<n>`, `coins=<n>`, `view=shop`;
  - `set.<node>:<property>=<value>`, resources included;
  - `strip=<n>/<seconds>` films motion as n shots;
  - `axe=x,y sweep=x,y/<s>` moves the mouse across while filming;
  - a renderer switch.
- **Contact sheets** (`tools/contact_sheet.py out.png --cols N a.png=caption ...`): one image with captions, nearest-neighbour scaling for pixel art. Option sheets ("four SELL signs", "five grade presets", "20 season × time looks") and before/after sheets for bug fixes. One sheet costs an agent far less context than many single shots.
- **Viewers for detail:** small dev scenes show one thing up close (split discs, end grain styles, coins and the sign, the grade display).
- The in-game view is the ground truth. Sheets are for comparing, not for proving feel. Say "untried by hand" when nothing was played.

## 7. Engine errors are failures (essential)

- **Idea:** install a logger during tests that collects engine and script errors, and fail the test on any unexpected one.
- **Here:** `tests/framework/script_errors.gd` (a `Logger` that collects script errors per test, thread-safe, because errors come from worker threads too) and `HullErrors` (counts the physics engine's refused convex hulls). An end-to-end drop test asserts zero refused hulls: old refused bodies fall through the ground at free fall, new ones rest within millimetres.
- **Why:** the physics engine silently refused some generated hulls for days. Pieces fell through the floor, and nobody saw it until the user pasted the warnings from the log. Also watch the log in general: one summary line is right for passing runs, but errors must reach the summary.

## 8. Runs that leave the user alone (essential on a shared machine)

- **Hidden windows** (Windows-specific): `tools/godot_hidden.sh` used as the engine path runs the game on a separate, invisible Windows desktop (`CreateDesktop`; output, exit codes and timeouts pass through; a job object kills the game with the launcher). `SHOW=1` shows it. Headless runs go straight through. Looks shots were identical (40/40, both renderers). Reference: `proto/hidden-launcher`. On Linux, a virtual display does the same; on macOS, check what works.
- **Muted:** test runs pass a dummy audio driver. User launches keep sound.
- **Own logs:** every tool script gives each run a log file in `test_runs/logs/` (`tools/godot_log.sh`, sourced by every script). Without it, runs logged into the player's own log folder, which keeps only five logs. Tool runs pushed out the user's play logs, and the in-game report attached a tool run's log tail.
- **Own data folders:** tests point user-data paths (bug reports, saves, read marks) into `test_runs/` through a variable, never the user's real folder.
- **No mouse capture, no focus stealing.** A headless browser of the tools' own (never the user's browser) for web checks: `tools/web_probe.mjs` prints the start time and saves a screenshot and the console.
- **Processes:** stop only what you started, by exact PID. If a stop is denied, leave the process alone and tell the user the exact command.

## 9. Quiet output (essential for agents)

One summary line per tool, full details only for failures, plus the path of the folder holding shots and dumps. Long output costs every later turn of the agent that printed it.

## 10. Known flakes

Record them; don't ignore them. One end-to-end scene failed about one run in five under GPU load, and passed when run alone. Note it in the instruction file and the report, so a reviewer doesn't chase it, and give it its own fix job later.
