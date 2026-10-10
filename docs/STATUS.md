# Delivery state — Afterlight 1.4.0

Implemented, tested, exported and packaged on `codex/afterlight`. Main remains
unchanged pending player approval. Feature milestone `78d8c0a`; final game source
`c647f0f`. Subsequent changes are verification documentation only.

## Current build

- Windows: `builds/windows/Afterlight.exe` and adjacent PCK/README.
- Portable archive: `builds/Afterlight-1.4.0-Windows.zip`, 39,604,673 bytes.
- SHA-256: `eb0cacbca68c9d88dc4e58e57563dca792fe19aefae9aa1a9eb7f04f7e1d9544`.
- Each of the archive's three entries matches the tested export (`package_v6.json`).
- Compatibility Web export succeeds; browser runtime/persistence remain unverified.
- Shipped Windows smoke passes with `editor=false`, including Anchor, Stasis and
  schema-4 mid-field saves as well as purchases, failed attempts and retries.

## Current game

65 upgrades: early Chord relay (60 light, no cores, after field 1) and fourteen
new Drift discoveries alongside the previous fifty. Chording is gated in core
rules and its contextual mouse cue. Tree nodes have distinct procedural icons,
real-rule previews and nonoverlapping hit areas down to minimum zoom.

New campaign fields from field 33 move 1/2/3/4 mines every 12/10/8/6 seconds by
region. Only hidden, unflagged, unworked cells can swap; pockets are excluded.
A 5×5 pointer/keyboard shelter (7×7 with Ballast), its clue-preserving halo, and
all recently departed zones are protected. Flags stay fixed; removing an ordinary
flag releases its tile. Worked ground and purchased anchors stay fixed forever.
All clues are recomputed before fresh drone deductions. Trials remain static.

New abilities include aimed anchors, manual flag/Pulse/beam/chord anchoring,
safe-wake tracing and excavation, drift energy, fleet interception, 12-second
Stasis, half-cost beams during Stasis, upgraded 7×7 plate-cracking anchors and
a final-quarter field freeze with a fleet cycle. UI has a warning clock, quiet
mint shelter outline, anchor corners, safe-wake diamonds, changed-clue flashes
and an optional illustrated legend. Safe-wake marks occupy the top-right corner
so plate stacks remain legible.

Save schema 4 preserves movement timers/sequence, focus/grace, surveyed cells,
anchors, traces and Stasis. Earlier saves keep their exact current field static
until the next new field and retain their formerly available chord ability.
The single-board reward loop, two-hit hull/cargo consequences, deterministic
retry, pinned upgrade selection and validated save backup from 1.3 remain.

## Evidence and limitations

90,113 core/persistence/preview/layout checks; 16,928 independent drift checks;
769 native UI checks and 59 viewport screenshots pass. All 65 icons have distinct
rendered signatures and all previews demonstrate actual rule effects. Twelve
trials and ninety matched clue-versus-spam cases pass. Pure spam completes only
3/18 tiny tutorial fixtures; clue play completes all 18 without strikes.

Three full campaign policies buy all 65 upgrades without strikes: fast 37.1m,
fleet-first 37.7m, deliberate 72.9m. Maximum purchase gaps: 1.7/1.8/4.1m. These
are simulations, not human playtime guarantees. The original three-hour target
remains unmet; this revision adds meaningful mechanics, not duration padding.

Agent-directed native play on a moving field used an anchor, Crossbeam, two
visible-clue deductions, flags and chording, then excavated a publicly marked
safe wake after 22 drift waves, with zero strikes. Quit/resume retained its 25
anchored tiles, field and wave sequence. This was a limited feature play session,
not a complete human campaign. Independent human enjoyment, browser runtime
and lower-end hardware remain unverified. Latest RTX 4090 sample: 6.90ms median,
8.03ms p95. Detailed evidence: [QA.md](QA.md); older delivery: [QA-1.3.md](QA-1.3.md).

No store integration, downloaded assets or generative art/audio were added. Keep
player reports and test artifacts ignored. All owned test processes have exited.
