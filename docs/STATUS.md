# Delivery state — Afterlight 1.3.0

The revision is implemented, verified, exported and packaged on `codex/afterlight`. Main remains unchanged. Tree milestone `e17e1d9` and gameplay source milestone `b50db5a` are pushed; subsequent changes are delivery documentation.

## Build

- Windows: `builds/windows/Afterlight.exe` with adjacent PCK and README.
- Portable archive: `builds/Afterlight-1.3.0-Windows.zip` (39,582,990 bytes), exactly those three tested files. Every entry hash matches its exported file. SHA-256: `ab89a2a8beb463ef8ee5b7e4f0e30b7e36689928cc1748a88043f4190809037e`.
- Compatibility Web: `builds/web/index.html` and supporting files. Export succeeds; browser runtime/persistence remain unverified.
- Standalone Windows smoke (`release_v5.log`) passes rendering, pinned node purchase, failed-attempt save/reload and native retry with `editor=false`.

## Gameplay and UI

- One board per site replaces 628 repeated strata with 96 rewarding fields. Every clear immediately banks cargo, pays 1/2/3 base cores by region pair, and permits the next site. Relay/Bounty/first-trial bonuses remain.
- Two hull segments per attempt. A strike loses half unbanked cargo, all energy and the chain; the second ends the attempt and loses remaining cargo. Retry has a new deterministic layout, with banked resources/upgrades preserved. One wrong chord costs at most one strike. Shield absorbs the first strike; a clean rating still requires zero hits.
- Cargo cannot fund purchases until cleared, closing the failed-attempt farming loophole. Hull, cargo and the clear’s core reward have a compact status strip with hover explanations and legend entries. Failure has a retry dialog and is saved.
- Tree click/arrows pin the right-hand purchase panel; hover only changes shading. A mint outline and corner tabs show the selection.
- Survey volley replaces obsolete Autonomous descent while retaining its save ID: three additional safe pulses at each opening, with its own matching icon and real-rule preview.
- v1/v2 saves retain exact current board state and already-banked resources. Their current board becomes the last board of that site; completed intermediate checkpoints settle once without repeating salvage.

## Current evidence

87,897 core/persistence checks pass, including 252 independent strike/migration/backup checks. The final native run passed 532 checks and 53 viewport captures, including inspected revised states. All twelve trials pass. Equal-work equipment comparison: early/middle/full builds take 284/11/7 simulated seconds.

All 50 upgrades are acquired by three full campaign policies: fast 35.8 minutes (1,590 inputs), fleet-first 36.9 (1,643), deliberate 71.2 (1,185). Maximum gaps between purchases are 1.8/1.8/4.2 minutes. These are simulation results, not human durations. The former three-hour fast-play target is no longer met: removing the reported repetitive padding takes priority over it. Additional duration requires new meaningful content.

Matched strategy checks: careful play completes 18/18 with zero strikes. Row/random blind spam at 10 Hz completes only 3/18 tutorial cases, versus clue play at 1 Hz. Tool-using blind policies complete 9/18 or 10/18, mostly the earliest and fully equipped late fields. This preserves the equipment payoff; it is not a proof that guessing can never win on an individual small board.

Agent-directed native play cleared the opening with flags/chords, bought Lens/Crossbeam, exercised strikes/failure/retry, and cleared the new field using visible clues, Pulse and beams. Bank and equipment survived retry. The initial harness reached its timeout during an interrupted user turn; the saved run was resumed, advanced to field 3 and quit mid-board. No independent human playtest is claimed.

## Delivery status and limits

Implementation, native play/checks, export smoke and archive verification are complete for this revision. Evidence is recorded in [QA.md](QA.md); package hashes are in ignored `test_runs/package_v5.json`. The original long-duration target, independent human enjoyment/pacing feedback, browser runtime/persistence and lower-end hardware remain unverified or unmet as stated above. Keep reports, screenshots and test saves ignored; do not commit player feedback.
