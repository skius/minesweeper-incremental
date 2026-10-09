# Validation

`tools/run.ps1` resolves the supplied engine from `GODOT_EXE` or `.env.local`; do not install another engine.

- `import`: refresh imports and class cache, headless.
- `test`: rules, persistence, malformed-save corpus, terrain and truthful upgrade preview regressions, headless.
- `shots`: native visual/input session on an isolated Windows desktop. Godot captures its viewport; no desktop capture is used.
- `balance`: three complete campaign policies, with one- and three-second decision intervals. The bounded engine timeout is fifteen minutes.
- `power`: three equipment tiers on an identical plated stratum.
- `trials`: visible-information completion and equipment-isolation checks for all twelve optional trials.
- `play`: normal visible game launch with audio.

Test artefacts belong in ignored `test_runs/`. Every mode writes its own log. Script errors, missing completion markers, nonzero exit codes and timeouts fail the run. Test saves are isolated with `--test-data`; the normal save is never read or overwritten. Native tests use dummy audio and a separate Windows desktop. The launcher owns the process handle and stops only that process on timeout.

Screenshots require a rendering device. Inspect meaningful PNG states after `shots`; headless tests do not validate presentation. The current session covers 45 captures, including ten contact sheets showing all fifty real-rule upgrade demonstrations before and after. Resolutions include 960×600, 1440×900, 1920×1080 and 1600×720. Native checks exercise pointer/keyboard controls, modal isolation, zoom/pan targeting, save retry paths, settings and trial controls. The late-game 180-frame sample writes `test_runs/performance_v2.json`.

`tests/player_policy.gd` reads visible clues, states and public plating, never the hidden mine map. `balance_v2.json` records complete campaigns and purchase timing; `power_curve.json` records fixed-work comparisons. Simulated duration does not establish human enjoyment or a guaranteed human minimum playtime.

`tools/hidden_run.py --scenario manual` exposes a development-only local command file. It returns visible clues and viewport captures for agent-directed play, loads only the isolated save, and persists its action history after each capture. This is not an independent human playtest.

## Exports

`powershell -File tools/export.ps1 -Target 'Windows Desktop'` builds the Windows release and copies the player README. `-Target Web` builds the Compatibility Web export. Run these sequentially because they share `test_runs/export.log`.

Test the shipped executable using `hidden_run.py --scenario release --engine <exported-exe> --project <export-folder> --log <absolute-log> --data-root <isolated-test-folder>`. The launcher omits the editor-only `--path` argument for release templates. The smoke checks rendering, actual input, a tree purchase, persistence and library notices from the exported PCK, and refuses to use normal saves.

The Windows archive must contain exactly `Afterlight.exe`, `Afterlight.pck` and `README.txt`; verify each entry against the exported file. Build files and screenshots remain ignored. Source and verification milestones are committed and pushed to `codex/afterlight`; main stays unchanged pending player approval. Record actual results and limitations in [QA.md](QA.md), and durable delivery state in [STATUS.md](STATUS.md).
