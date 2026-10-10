# Revision 1.3.0 verification

This supersedes [1.2.1](QA-1.2.1.md). This revision removes repeated strata between rewards, makes failed attempts lose unbanked cargo, and pins tree selection on click. All launches use the supplied Godot 4.7.2 Compatibility renderer. Test saves/logs are isolated; native windows run muted on a separate Windows desktop. No third-party or generative assets were used.

## Rules, economy and saves

87,897 checks pass in `test.log`. This includes the independent reviewer’s 252 strike/escrow/retry/migration checks, malformed-save backup recovery, deterministic truthful boards, first-clear choices, tool combinations and all 50 real-rule upgrade previews. A lower count than 1.2.1 reflects the removed repeated-strata test iterations, not skipped failure checks.

Two unprotected strikes fail an attempt. The first removes half current cargo (rounded up), drains energy and clears the chain; the second discards remaining cargo. Shield absorbs the first strike; it still lowers the rating and loses Bounty’s perfect-clear core. One mistaken chord costs at most one strike. Every mutation/automation path stops after failure, even when a nested Seismic action uncovered the last safe tile first. Failure wins over completion and no payout occurs. Buying from cargo is impossible.

Retries preserve banked credits/cores/upgrades, reset temporary state, and use an attempt-indexed deterministic seed. New-schema saves require damage/failure/attempt fields and reject impossible unopened failures. Old v1/v2 saves retain exact board state and banked resources, without retroactive hull damage. Old active board earnings are not credited twice; old completed intermediate strata become a finished site without replaying flag salvage. Migration is idempotent after saving. The validated backup remains available.

The campaign has 96 boards, one per site. Each pays 1/2/3 base cores by region pair plus applicable relay, trial and Bounty bonuses. First-clear earnings still fund Lens plus one 100-light starter even after a surviving hit. Survey volley replaces obsolete Autodescent with three extra safe openings.

| Campaign policy | Decision interval | Minutes | Inputs | Maximum purchase gap |
|---|---:|---:|---:|---:|
| Fast |1second|35.8|1,590|1.8minutes|
| Fleet-first |1second|36.9|1,643|1.8minutes|
| Deliberate |3seconds|71.2|1,185|4.2minutes|

All policies finish with 50 upgrades and zero solver/tool strikes. Final Legacy purchase arrives at site 92. These are models (`balance_v2.json`), not independent human times or optimal speedruns. The former three-hour fast-player target is no longer met; removing the reported repeated work takes priority over duration padding. New meaningful content would be needed to restore that duration.

All 12 optional trials pass. On identical plated site 49, early/middle/full equipment takes 284/11/7 seconds and 86/10/6 inputs, with zero strikes (`power_curve.json`).

## Anti-spam comparison

`strategy_balance.gd` runs 90 cases: 18 matched fixtures across fields 1, 6, 21, 48, 73, 96 and three attempt seeds, with natural equipment from the current full campaign. The visible-clue policy acts once per second. Blind row/random policies click ten times per second, with additional versions using the same footprint-scored safe tools, Pulse and passive fleet. No mode reads hidden mines. Failed attempts retry immediately, with no time penalty beyond one input. Each blind case gets at least 120 seconds or three times the solver duration.

| Policy | Completed fixtures | Failed attempts | Total simulated seconds | Banked light |
|---|---:|---:|---:|---:|
| Clue policy |18/18|0|298.3|61,076|
| Row spam |3/18|1,667|1,814.9|372|
| Random spam |3/18|1,470|1,820.0|388|
| Row + toolkit |9/18|1,006|1,111.7|46,826|
| Random + toolkit |10/18|709|1,021.1|49,336|

Pure spam only completes the tiny tutorial fixtures, sometimes faster by luck. Tool-using policies can complete fully equipped late fields quickly, which is the intended automation payoff. This is evidence against blind clicking as an efficient campaign strategy, not proof that guessing can never win on one small board. Regression thresholds now fail when blind clicking becomes competitive in completion count or banked light per second. Results: `strategy.log` and `strategy_balance.json`.

## Native input, visuals and play

532 native checks pass over 53 Godot viewport captures (`shots.log`). Tests cover persistent clicked selection while hovering another node and purchasing, keyboard selection, hull damage/failure/retry, immediate single-board rewards, disclosure, settings, modal isolation, field controls, zoom/pan, aimed costs, small/wide windows, save errors and all upgrade previews.

Inspected captures include `v5_41_tree_pinned`, `v5_42_single_field_clear`, `v5_43_hull_damaged`, `v5_44_retry`, early/full legends and the late trial. Selection has a fixed mint frame and corner tabs; hover uses a thin neutral edge. Hull, cargo and projected cores have distinct spacing in the field status strip; idle drone positions moved to the opposite end. The existing centre axes and equipment gaps remain. Legend entries match hull/cargo behavior and only mention Shield when installed. Final late-game sample: 6.95 ms median/7.32 ms p95, 872 draw calls on RTX 4090; not a minimum-hardware claim.

Agent-directed native play used visible clues, flags/chords, Pulse and aimed Crossbeam. It cleared field 1, bought Lens/Crossbeam, exercised first-hit damage and second-hit failure on field 2, retried the fresh layout and cleared it without a strike. Banked resources/upgrades survived. The first launcher reached its 900-second timeout during an interrupted user turn; the saved field was then reloaded, advanced to field 3, opened and quit mid-board. `manual_v5_resume.log` exits successfully. This is an agent play session plus scripted checks, not an independent human playtest.

## Release

Source milestone and Windows/Web export, standalone smoke and archive verification are being finalized. Browser runtime/persistence and lower-end hardware remain unverified. Art/audio remain procedural; no store integration was added.
