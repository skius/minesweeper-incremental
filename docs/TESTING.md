# Validation

`tools/run.ps1` is the shared entry point. Set `GODOT_EXE` (or use `.env.local`).

- `import`: refresh Godot imports and class cache, headless.
- `test`: pure rules and persistence regression suite, headless.
- `shots`: deterministic native visual/input sessions on an isolated Windows desktop. Godot captures its own viewport; no desktop capture is used.
- `play`: launch the normal game, visible with audio.

Test artefacts belong in ignored `test_runs/`. Every test run has its own log. Script errors, missing completion markers, nonzero exit codes and timeouts fail a run. Tests select an isolated save path via user arguments; the normal save is never read or overwritten.

Screenshots require a rendering device; headless mode cannot validate presentation. Always inspect the resulting PNGs. Record actual results and limitations in `docs/QA.md`.

The visual harness also checks settings persistence, pause isolation, keyboard focus, local reports, readable text bounds and 960×600 / 1920×1080 layouts. A 180-frame late-game sample writes `test_runs/performance.json`.

`tools/hidden_run.py --scenario manual` exposes a development-only local command file and returns only visible clues for visual decision play. It keeps an action history; no hidden mine information is exposed.

`tools/export.ps1` creates the Windows release. Test the shipped executable with `hidden_run.py --scenario release --engine <exported-exe> --project <export-folder> --log <absolute-log> --data-root <isolated-test-folder>`. Release templates intentionally reject `--path`, so the launcher omits that editor-only argument for this mode. The smoke checks rendering, real input, persistence and library notices from the actual PCK; it refuses to use the player's save directory.
