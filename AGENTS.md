# Afterlight

A complete, desktop-first Minesweeper incremental game, built in Godot 4.7.2 using Compatibility rendering. Web-compatible code is a requirement; store integration is out of scope.

## Working conventions
- Read `docs/DESIGN.md`, `docs/STATUS.md`, and `docs/TESTING.md` before changing the game.
- Keep game rules in `game/core/`, presentation in `game/ui/`, and persistent data in `game/save_store.gd`.
- Use deterministic random streams owned by each system. No global RNG in game rules.
- Use the engine command line. `tools/run.ps1` resolves `GODOT_EXE` or `.env.local`. Never install another engine.
- Small, tested commits; push each worthwhile milestone. Current delivery branch: `codex/afterlight`. Keep main unchanged until the player approves the build.
- Test launches are muted, on a separate Windows desktop, with logs and saves under `test_runs/`. Stop only processes created by the test launcher, by their own handles/PIDs.
- Capture screenshots through Godot's viewport. Inspect meaningful states and record visual decisions. Don't confuse scripted input tests with human playtests.
- Save and load must survive a mid-board quit. Retain a validated backup. Tests never touch player saves.
- Inputs must work without mouse capture. Include keyboard play, flag mode, reduced motion, separate music/SFX controls, fullscreen, and legible clue symbols.
- Retain the source notes in `process_distillation/`; apply lightweight useful practices, not the former project's full orchestration machinery.
- Keep durable decisions and outstanding work in `docs/STATUS.md`, not private agent memory. Do not commit player reports or verbatim conversation text.
- No third-party asset downloads are needed. Art and audio are procedural and repository-owned; typography uses Godot's bundled font.

## Commands
`powershell -File tools/run.ps1 -Mode import`
`powershell -File tools/run.ps1 -Mode test`
`powershell -File tools/run.ps1 -Mode shots`
`powershell -File tools/run.ps1 -Mode play`

See `docs/TESTING.md` for detailed validation and limitations.
