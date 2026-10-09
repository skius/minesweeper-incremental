# Delivery state — Afterlight 1.2.1

The 1.2.1 revision is implemented, tested, exported and packaged on `codex/afterlight`. Main remains unchanged pending player approval. The source build is `9827bec`; subsequent changes are verification documentation.

## Build

- Windows: `builds/windows/Afterlight.exe` with its adjacent PCK and README.
- Portable archive: `builds/Afterlight-1.2.1-Windows.zip` (39,759,848 bytes). It contains exactly the tested executable, PCK and player README; SHA-256 of every entry matches the exported file. Archive SHA-256: `667d42bd951ca23c0d5c363b2c154853f3053963bce57ec4afc88abf8a0238d4`.
- Compatibility Web: `builds/web/index.html` and supporting files. Export succeeds; browser runtime/persistence remain unverified.
- No store integration, external services, generative media or downloaded assets were added. Art/audio are procedural and repository-owned.

## Design and feedback applied

The 1.2.1 UI pass replaces inconsistent field placements with shared centre axes and a measured equipment dock. Icons occupy recessed wells with hover/armed/activation feedback, and prices have their own row. Native checks now cover actual aimed states, where the former hints overlapped energy and price controls. Modal titles and settings rows share aligned centres. A retained late tree selection can no longer leak future discoveries into a new game.

An optional field Legend opens with its labelled button or L. It uses seventeen-pixel explanations and the same procedural markers as the board: corner crystals, metal plate layers, current Pulse equipment and the safe-ground counter. Samples and wording adapt to Compass and Oracle. Reward numbers animate near the currency display without covering clues; discounted aimed tool prices match the energy meter.

A quiet 6×5 opening introduces Pulse after the first reveal and Grow/currencies after the first clear. That clear funds Lens plus either Crossbeam or Scout; the next clear can fund the other. Only owned or currently reachable discoveries appear. All fifty upgrades have distinct procedural symbols with related shapes within their six families, and animated demonstrations driven by actual game rules.

The interface uses consistent bevelled retro controls, restrained colour and contextual pictograms/hover help. Energy storage, aimed prices and tool buttons share a symbol. Chain/fleet readouts sit inside the terminal, every plating depth has a visible marking, and zoom/pan targeting remains correct without a subsequent pointer movement. The viewport expands to widescreen and ultrawide displays; zoom, overview navigation and keyboard following keep small-window clues readable.

The six-region campaign has 96 sites and 628 strata, an ending and endless continuation. Shelf, shaft and geode layouts change excavation geometry and pocket placement from site 7 while preserving truthful clues and independent deterministic streams. Fifty discoveries change beams, information, drilling, automation and resource interactions. Optional trials scale to dense plated layouts without added strata; Survey trials park beams/fleet, while Fleet trials showcase owned powers. Existing campaign and trial saves retain their stored layouts.

Menus, pause, settings, keyboard play, flag mode, reduced motion, independent music/SFX levels, fullscreen, high-contrast clues and local reports are present. Exact mid-board saves retain a validated backup. Corrupt data is rejected before conversion; write failures expose retry paths. Tests never touch player saves.

## Verification and limits

- 89,764 rule/persistence checks pass, including an independent malformed-save corpus, old-save compatibility, terrain, accurate previews and upgrade synergies.
- 508 native input/state/layout checks pass with 50 Godot viewport captures; meaningful states and all fifty preview/symbol designs were inspected. The critical reviewer verified the final targeting, plating and text fixes and reported no remaining blocking UI issue.
- All twelve revised trials complete without strikes. The reviewer independently ran 96 old/new comparisons with natural purchase sets and complete equipment. The final Survey/Fleet trials increased from 14/3 to 61/16 simulated seconds, without adding repeated strata.
- Complete campaign policies acquire all fifty upgrades with no solver/tool strikes or economic dead ends: fast tools/fleet policies take 163.5/165.2 minutes; a deliberate policy takes 319.6. These are pacing models, not guaranteed human durations. On identical plated work, early/middle/full equipment takes 284/11/8 simulated seconds.
- During revision 1.2, agent-directed native play used visible clues, flags, chords and beams, cleared two sites without strikes, bought Lens/Crossbeam/Scout, observed autonomous work and quit mid-board. The player supplied a short previous-build session; no independent full-campaign human playtest is claimed.
- The actual exported Windows executable passes boot, render, field-legend input, purchase, save and reload checks. Its archive is verified. The late-game native sample is 6.95 ms median / 7.03 ms p95 on an RTX 4090; lower-end performance is unverified.

Implementation and packaging for this revision are complete. Remaining release evidence is independent human enjoyment/pacing feedback, lower-end hardware testing and browser runtime validation. Continue from this integrated build when new feedback arrives. Details: [QA.md](QA.md), [DESIGN.md](DESIGN.md), [TESTING.md](TESTING.md). Earlier quality records are retained as `QA-1.0.md`, `QA-1.1.md` and `QA-1.2.md`.

## Working conventions retained

Read `process_distillation/` as lightweight practice rather than importing its former orchestration machinery. Keep deterministic rules in `game/core/`, presentation in `game/ui/` and persistence in `game/save_store.gd`. Use the supplied engine through `tools/run.ps1`. Native tests run muted on an isolated desktop with owned process handles. Keep raw player feedback and reports local; they are not committed. Use small tested commits and push worthwhile milestones to the delivery branch.
