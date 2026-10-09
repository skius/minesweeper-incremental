# Revision 1.2 verification

This supersedes the [1.1 record](QA-1.1.md). Native sessions use the supplied Godot 4.7.2 with Compatibility rendering, dummy audio, a separate Windows desktop and isolated saves under `test_runs/`. The player supplied feedback from a short session on the previous build; that feedback drove this revision. No independent full-campaign human playtest is claimed.

## Rules, saves and progression

- 89,764 rule/persistence checks pass. These include an independent 1,924-case malformed-save corpus, accurate upgrade demonstrations, terrain determinism, every possible first opening, mechanical upgrade regressions and validated backup recovery. The loader checks finite values, types, cell arithmetic and reward state before accepting data. Loading a clone no longer shares mutable reward dictionaries with its source.
- The first clear funds Lens and exactly one of Crossbeam or Scout, with the next clear funding the other. Future rank/prerequisite nodes stay hidden. Terrain rotates through shelf, shaft and geode forms from site 7; mine placement and clue arithmetic use an independent deterministic stream. Existing saves retain their stored generation form.
- Three complete visible-information policies reach the ending, acquire all fifty discoveries and encounter no solver/tool strikes or economic dead ends. These policies use deductions, flags, chords, footprint scoring and free probes; they do not read the hidden mine map.

| Policy | Decision interval | Campaign minutes | Inputs |
|---|---:|---:|---:|
| Tools first | 1 second | 163.5 | 8,133 |
| Fleet first | 1 second | 165.2 | 8,275 |
| Deliberate craft | 3 seconds | 319.6 | 5,534 |

All contain 628 strata across 96 sites. Menus receive four seconds per site and purchases two seconds each, with no artificial waiting inserted. The longest purchase gaps are 11.2, 11.1 and 18.9 minutes. The final discovery arrives at site 92, at minutes 152.3, 153.9 and 300.7 respectively. These are pacing models, not verified human durations or optimal speedruns; enjoyment remains a human judgement.

On the identical plated site-49 stratum, early/middle/complete equipment takes 284/11/8 simulated seconds and 86/10/6 inputs to uncover 203 safe tiles, with zero strikes. This separately checks that equipment overpowers fixed work instead of only matching larger fields.

## Native interface and visual review

- 338 native input/state/layout checks pass over 45 viewport captures. Coverage includes progressive disclosure, all fifty unique rendered symbols and descriptions, ten before/after preview contact sheets, beams, plating, descent, save failures/retries, menus, settings, trial restrictions and the ending.
- Captures were inspected at 960 × 600, 1440 × 900, 1920 × 1080 and 1600 × 720. Viewport expansion removes letterboxing. Field zoom preserves clue readability at the smallest window; keyboard navigation follows the selected tile. Pointer aim is reprojected immediately after zoom, pan or overview navigation, with clicks tested without intervening mouse motion.
- The terminal contains chain/fleet readouts and titlebar controls; counters no longer float across its border. Shared bevelled surfaces, restrained colours and six related icon families give all fifty nodes distinct identities. All six plating layers visibly differ, including 6→3 drilling and 6→2 beam outcomes.
- Preview boards execute actual miniature game sessions. Clues, tool footprints, workers and outcomes come from real rules. Energy storage and actual aimed costs share one symbol beside the tools. Reduced motion keeps the final demonstration state visible.
- The critical reviewer found and verified fixes for stale camera targeting, indistinguishable upper plating layers and corrupted text. Earlier review also supplied independent save regressions and identified reward/automation issues. This is evidence of a review, not a claim that every possible bug has been found.
- A visible-clue agent session cleared the opening, bought Lens/Crossbeam/Scout, cleared a second site without strikes, observed the Scout uncover eighteen additional tiles and quit on the third board. The resumed session recorded 27 harness actions. This is agent-directed native play, distinct from automated campaign policies and the player's short prior-build session.
- The 180-frame late-game sample measured 6.95 ms median / 7.05 ms p95 between process frames and 848 draw calls on an RTX 4090. This is not a minimum hardware claim.

## Trials and delivery

All twelve revised trials complete without strikes. The critical reviewer ran 96 comparisons using actual purchase sets from all three campaign policies and complete equipment, testing both old and proposed fields with five 0.2-second updates per one-second decision. The first pair stays familiar; later trials use denser shafts, shelves and geodes with two to six plating layers. The final Survey trial takes 61 simulated seconds / 61 actions (previously 14/14), and the Fleet trial 16 seconds / 11 actions (previously 3/3). Earlier fields remain faster with late equipment. Each trial stays one board; saved old trials retain their exact generated or unopened layouts. Survey trials suppress all fleet work, including a Coordinated strike triggered by a manual chord; only usable tools are displayed.

All geometry, textures, icons, music and sound are procedural and repository-owned. No image/audio generation service or downloaded media was used. Six oscillator-based scores and their synthesis source are retained; engine/library licences remain accessible in-game.

Windows and Compatibility Web exports both succeed. The actual Windows executable passes boot, render, input, a tree purchase, save and reload checks with `editor=false`. The verified 1.2 archive contains exactly that executable, its PCK and the player README (39,752,151 bytes; archive SHA-256 recorded in STATUS.md). Each entry matches its exported file. Source build: `4e5bd6c`. The executable is tested independently of the editor; browser runtime/persistence and lower-end hardware remain unverified. Tests never touch normal player saves. Raw player feedback and reports remain local and are excluded from commits. Store integration remains outside scope.
