# Delivery state — Afterlight 1.2

## Active UI revision 1.2.1
Player feedback identified inconsistent control spacing and unclear field symbols. The interface now uses explicit viewport geometry, a centred equipment dock with separate icon/price rows, mounted tool glyphs, dimensional crystals and layered metal plates. An optional field legend (button or L) explains encountered symbols using the same drawings, including the safe-ground counter. Resource totals animate beside currency instead of covering clues. A stale discovery selection after restart is clamped to a visible node. Current checks: 89,764 rule/save assertions and 508 native checks with 50 viewport captures. The independent visual review reports no remaining overlap in the reviewed states. Legend samples now match installed equipment and actual tile-corner markers, with larger body text. Final exports are being refreshed. Prior 1.2 build below is superseded once the new export is packaged.

The 1.2 revision is implemented, tested, exported and packaged on `codex/afterlight`. Main remains unchanged pending player approval. The source build is `4e5bd6c`; subsequent changes are verification documentation. The requested refinement deadline of 9 October 2026, 10:00 CEST has passed. No timer or scheduled automation was used.

## Build

- Windows: `builds/windows/Afterlight.exe` with its adjacent PCK and README.
- Portable archive: `builds/Afterlight-1.2.0-Windows.zip` (39,752,151 bytes). It contains exactly the tested executable, PCK and player README; SHA-256 of every entry matches the exported file. Archive SHA-256: `d28386fc9493da5312816e3540f6f753e1964ca970b74a7ae6589fecca82d2a5`.
- Compatibility Web: `builds/web/index.html` and supporting files. Export succeeds; browser runtime/persistence remain unverified.
- No store integration, external services, generative media or downloaded assets were added. Art/audio are procedural and repository-owned.

## Design and feedback applied

A quiet 6×5 opening introduces Pulse after the first reveal and Grow/currencies after the first clear. That clear funds Lens plus either Crossbeam or Scout; the next clear can fund the other. Only owned or currently reachable discoveries appear. All fifty upgrades have distinct procedural symbols with related shapes within their six families, and animated demonstrations driven by actual game rules.

The interface uses consistent bevelled retro controls, restrained colour and contextual pictograms/hover help. Energy storage, aimed prices and tool buttons share a symbol. Chain/fleet readouts sit inside the terminal, every plating depth has a visible marking, and zoom/pan targeting remains correct without a subsequent pointer movement. The viewport expands to widescreen and ultrawide displays; zoom, overview navigation and keyboard following keep small-window clues readable.

The six-region campaign has 96 sites and 628 strata, an ending and endless continuation. Shelf, shaft and geode layouts change excavation geometry and pocket placement from site 7 while preserving truthful clues and independent deterministic streams. Fifty discoveries change beams, information, drilling, automation and resource interactions. Optional trials scale to dense plated layouts without added strata; Survey trials park beams/fleet, while Fleet trials showcase owned powers. Existing campaign and trial saves retain their stored layouts.

Menus, pause, settings, keyboard play, flag mode, reduced motion, independent music/SFX levels, fullscreen, high-contrast clues and local reports are present. Exact mid-board saves retain a validated backup. Corrupt data is rejected before conversion; write failures expose retry paths. Tests never touch player saves.

## Verification and limits

- 89,764 rule/persistence checks pass, including an independent malformed-save corpus, old-save compatibility, terrain, accurate previews and upgrade synergies.
- 338 native input/state/layout checks pass with 45 Godot viewport captures; meaningful states and all fifty preview/symbol designs were inspected. The critical reviewer verified the final targeting, plating and text fixes and reported no remaining blocking UI issue.
- All twelve revised trials complete without strikes. The reviewer independently ran 96 old/new comparisons with natural purchase sets and complete equipment. The final Survey/Fleet trials increased from 14/3 to 61/16 simulated seconds, without adding repeated strata.
- Complete campaign policies acquire all fifty upgrades with no solver/tool strikes or economic dead ends: fast tools/fleet policies take 163.5/165.2 minutes; a deliberate policy takes 319.6. These are pacing models, not guaranteed human durations. On identical plated work, early/middle/full equipment takes 284/11/8 simulated seconds.
- Agent-directed native play used visible clues, flags, chords and beams, cleared two sites without strikes, bought Lens/Crossbeam/Scout, observed autonomous work and quit mid-board. The player supplied a short previous-build session; no independent full-campaign human playtest is claimed.
- The actual exported Windows executable passes boot, render, input, purchase, save and reload checks. Its archive is verified. The late-game native sample is 6.95 ms median / 7.05 ms p95 on an RTX 4090; lower-end performance is unverified.

Implementation and packaging for this revision are complete. Remaining release evidence is independent human enjoyment/pacing feedback, lower-end hardware testing and browser runtime validation. Continue from this integrated build when new feedback arrives. Details: [QA.md](QA.md), [DESIGN.md](DESIGN.md), [TESTING.md](TESTING.md). Earlier quality records are retained as `QA-1.0.md` and `QA-1.1.md`.

## Working conventions retained

Read `process_distillation/` as lightweight practice rather than importing its former orchestration machinery. Keep deterministic rules in `game/core/`, presentation in `game/ui/` and persistence in `game/save_store.gd`. Use the supplied engine through `tools/run.ps1`. Native tests run muted on an isolated desktop with owned process handles. Keep raw player feedback and reports local; they are not committed. Use small tested commits and push worthwhile milestones to the delivery branch.
