# Revision 1.4.0 verification

Supersedes [1.3.0](QA-1.3.md). Supplied Godot 4.7.2, Compatibility renderer.
Native launches were muted on an isolated Windows desktop; all test saves/logs
are under `test_runs/`. No player save was used.

## Rules and persistence

`test.log`: **90,113** core, persistence, preview and layout checks pass.
`drift.log`: **16,928** independent adversarial drift checks pass. The reviewer
wrote the dedicated runner; the primary agent integrated and ran its final form.

Coverage includes exact clue arithmetic/mine counts, orthogonal swaps, unchanged
pockets/flags/worked ground, pointer shelter plus halo across repeated waves at
edges/corners, all recent focus grace zones, correct input ordering, no movement
inside action transactions or while inactive/failed/finished/frozen, no reward
for empty waves, and atomic safe wake reservation before reward callbacks.

All fourteen Drift upgrades have direct effect checks and truthful before/after
previews; the new basic chord upgrade is tested locked and unlocked. Old save
migration preserves chording where previously available and keeps the current
board static. Schema 4 requires and validates every drift field, bounds/arrays,
trace safety, clocks, focus and grace. Uninterrupted versus save/reload tick
sequences choose identical future swaps. Prior strike/escrow/backup regressions
still pass. Clicking one incorrect chord still costs at most one hull hit.

## Campaign and challenge

| Policy | Decision interval | Minutes | Inputs | Largest purchase gap |
|---|---:|---:|---:|---:|
| Fast | 1 second | 37.1 | 1,651 | 1.7 minutes |
| Fleet-first | 1 second | 37.7 | 1,675 | 1.8 minutes |
| Deliberate | 3 seconds | 72.9 | 1,215 | 4.1 minutes |

Every policy acquires all 65 upgrades and completes 96 fields without a strike.
Final Legacy purchase occurs at field 92. `balance_v2.json` records each purchase.
These are simulations; the original three-hour target remains unmet.

Identical initial field 49: early/mid/full equipment takes 106/11/8 seconds and
105/10/6 inputs, all strike-free (`power_curve.json`). Drift uses the actual
rules, so later wave histories can differ between equipment profiles. All twelve
optional trials remain static and pass their equipment restrictions.

Ninety matched strategy cases pass (`strategy_balance.json`). Clue play completes
18/18, zero failures, 302.5 total seconds, 60,879 banked light. Plain row/random
spam at 10Hz completes 3/18 each (tutorial only), with 1,663/1,459 failed attempts
and 372/388 banked light. Tool-using row/random policies complete 9/18 and 11/18;
late equipment retains its intended ability to overpower earlier work.

## Native play, UI and screenshots

**769** native input/state checks and **59** viewport captures pass (`shots.log`).
Tests include all prior menus/settings/disclosure, tree pinned-selection purchase,
field zoom/pan/keyboard targets, hull/retry, small/wide windows and save failures.
New native checks cover timed movement, stable sheltered clues, modal clock pause,
Anchor/Stasis shortcuts, energy spending, keyboard shelter movement, anchor and
Stasis persistence, full 65-node layout and 65 distinct rendered icon signatures.
Twelve contact sheets show all actual upgrade demonstrations before and after.

Inspected `v6_01_drift_shelter`, `v6_02_drift_legend`, `v6_03_stasis_and_anchor`,
`v6_04_drift_tree`, icon families and new upgrade previews. Adjusted compressed
branch forks until all node hit areas were disjoint even at minimum zoom. The
legend mirrors actual tile marks. Manual play revealed safe-wake/plate overlap;
wake diamonds moved to the top-right corner, leaving the central plate stack and
top-left anchor mark clear. Native screenshots and the resumed play capture were
inspected after that change. Latest 180-frame RTX 4090 sample: 6.901ms median,
8.026ms p95, 1,030 draw calls; not a minimum-hardware claim.

Agent-directed native play used a controlled field-41 starting equipment fixture
and only the public clues/marks thereafter. It opened safely, paid for a 5×5
anchor, used Crossbeam, deduced and flagged two mines, then chorded a satisfied
number. It excavated a visible safe wake after 22 movement waves, with no strike.
Quit/relaunch restored the exact field, wave 22 and 25 pinned cells. Logs:
`manual_v6.log` (11 commands), `manual_v6_resume.log` (3); the initial history is
preserved as `manual_v6_history.json`. This is agent-directed feature play plus
scripted tests, not an independent human playtest or a completed human campaign.

## Release

Final game source `c647f0f` (feature milestone `78d8c0a`). Windows and Compatibility
Web exports succeed. The actual Windows executable passes `release_v6.log` with
`editor=false`, exercising rendering, clicked tree purchase after hovering another
node, failed-attempt persistence/retry, protected drifting ground, native Anchor
and Stasis buttons, and schema-4 saves. Its `release-drift.png` viewport was inspected.

`builds/Afterlight-1.4.0-Windows.zip`: 39,604,673 bytes, exactly `Afterlight.exe`,
`Afterlight.pck`, `README.txt`. All entry hashes match the tested export; README
matches source. SHA-256:
`eb0cacbca68c9d88dc4e58e57563dca792fe19aefae9aa1a9eb7f04f7e1d9544`.
Evidence: `package_v6.json`. Browser runtime/persistence, lower-end performance
and independent human enjoyment remain unverified. All assets remain procedural.
