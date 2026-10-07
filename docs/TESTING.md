# Validation

`tools/run.ps1` is the shared entry point. Set `GODOT_EXE` (or use `.env.local`).

- `import`: refresh Godot imports and class cache, headless.
- `test`: pure rules and persistence regression suite, headless.
- `shots`: deterministic native visual/input sessions on an isolated Windows desktop. Godot captures its own viewport; no desktop capture is used.
- `play`: launch the normal game, visible with audio.

Test artefacts belong in ignored `test_runs/`. Every test run has its own log. Script errors, missing completion markers, nonzero exit codes and timeouts fail a run. Tests select an isolated save path via user arguments; the normal save is never read or overwritten.

Screenshots require a rendering device; headless mode cannot validate presentation. Always inspect the resulting PNGs. Record actual results and limitations in `docs/QA.md`.
