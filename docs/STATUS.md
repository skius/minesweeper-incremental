# Delivery state — Afterlight 1.1

## Active revision 1.2
Refinement is in progress: visual onboarding instead of persistent instruction sentences, one consistent retro chrome system, restrained colour, mechanically accurate upgrade demonstrations and an independent critical agent audit. Continue implementation, native visual review and gameplay validation through at least 9 October 2026, 10:00 CEST; check actual time before concluding. No timer or scheduled automation is used. The 1.1 delivery record below is the baseline, not sign-off for this revision.

First refinement checkpoint: native screenshots now show pictogram input cues, footer clue inspection, shared bevelled surfaces and a neutral discovery tree. Pointer exit, open-cell keyboard focus, compass visibility and drone worker assignment are corrected. Core audit fixes cover per-layer salvage, manual-only seismic rhythm, nested-action reward ordering, shared plate-damage synergies, affordable recycler pricing and stable trial identity. Current regression result: 71,157 rules/save assertions; the latest native UI pass has 172 checks over 27 captures. These are intermediate results. Outstanding audit work includes stronger save validation, modal keyboard isolation/navigation, visually distinct icons for all fifty upgrades, truthful previews, tool impact balancing, narrow-window readability and final pacing/export revalidation.

## Current build
The integrated revision is complete on `codex/afterlight`. Main remains unchanged pending player review. Standalone Windows and Compatibility Web exports are under ignored `builds/`; the Windows archive is `builds/Afterlight-1.1.0-Windows.zip`. No store integration was performed.

## Design delivered
- Modern Windows 95/XP-inspired field terminal: bevelled tiles, inset counters, procedural evening scenery and animated feedback.
- A quiet 6 × 5 opening; Pulse appears after opening the field, Grow and currencies after its first clear. Owned equipment introduces further controls. Hover help and animated demonstrations replace permanent instruction panels.
- Fifty discoveries on six branches from a central lens. Tools change targeting, footprints, excavation, resource loops and fleet behaviour.
- Six regions, 96 sites and 628 strata. Larger, denser and plated fields give stronger equipment new work. Twelve optional mastery trials, a campaign ending and endless exploration remain available.
- Main menu, pause, settings, keyboard play, flag mode, reduced motion, separate music/SFX controls, fullscreen and high-contrast clues. Exact mid-field saves retain a validated backup and migrate version-1 saves.
- All art, textures, music and sound are procedural and repository-owned. No image/audio generation service or downloaded media was used.

## Verification
- 71,127 core/persistence assertions and 189 native input/state/layout checks pass. Twenty-seven viewport captures were inspected at 960 × 600, 1440 × 900 and 1920 × 1080.
- An agent played the opening using visible clues, flags and chords, then purchased the first two upgrades through native input. This is not independent human playtesting.
- Three complete campaign simulations acquire all fifty discoveries without solver/tool strikes or economic dead ends. One-second policies take 175.7 and 173.0 minutes; a three-second policy takes 344.0 minutes. These are pacing models, not verified human durations.
- On the same stratum, early/mid/complete equipment takes 100/12/5 simulated seconds, demonstrating power growth against fixed work.
- Both release exports succeed. The actual Windows executable passes isolated native boot, render, input, tree purchase, save and reload checks. Browser runtime and persistence remain unverified.
- A 180-frame late-game sample records 6.9 ms median / 8.4 ms p95 between process frames on an RTX 4090. This is not a minimum hardware claim.
- The Windows archive includes only the tested executable, PCK and player README; its entries are checked against those files.

## Working decisions and remaining validation
Use one integrated branch, small tested commits and frequent pushes. The inherited process notes have been read and adapted; retain them in `process_distillation/`. Keep native tests muted on a separate Windows desktop and test saves under `test_runs/`. Stop only launcher-owned processes.

No implementation or packaging work remains for this revision. Independent human enjoyment/pacing feedback, lower-end hardware testing and browser runtime validation remain release-quality evidence to gather; none is claimed complete. Begin future changes from this integrated build. Detailed evidence: `docs/QA.md`; design: `docs/DESIGN.md`; commands: `docs/TESTING.md`. The superseded 1.0 quality record is retained in `docs/QA-1.0.md`.
