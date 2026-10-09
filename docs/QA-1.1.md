# Revision 1.1 verification

This supersedes the original [1.0 quality record](QA-1.0.md). All native sessions use Compatibility rendering on the supplied Godot 4.7.2, on a separate Windows desktop with dummy audio and isolated test saves. No independent human playtest is claimed.

## Rules and progression
- 71,127 rule/persistence checks pass, including plated excavation, shape upgrades, depth transitions, non-duplicated rewards, exact saves and version-1 migration. Every one of the fifty prerequisite paths reaches the origin without a cycle.
- Three complete campaign policies reach the ending and acquire all fifty discoveries without solver/tool strikes or economic dead ends. The policy uses visible deductions, correct flags, chording, footprint scoring, free probes and overdrive. Menus receive four seconds per site and purchases two seconds each; no fabricated long pauses.

| Policy | Decision interval | Campaign minutes | Inputs |
|---|---:|---:|---:|
| Tools first | 1 second | 175.7 | 8,894 |
| Fleet first | 1 second | 173.0 | 8,873 |
| Deliberate craft | 3 seconds | 344.0 | 5,997 |

All campaigns contain 628 strata. The deliberately fast policies know the logical deductions immediately; they are not a shortest-possible speedrun solver. Human skill, chording habits, reading and build choices can change the duration substantially. Mastery trials are additional content, excluded from these timing figures. The longest gap between purchases in the final fast run is 11.1 minutes; most are shorter, and the last discovery arrives at site 92.

An identical site-49 stratum provides a separate power check: early equipment needs 100 seconds / 100 inputs; midgame equipment 12 seconds / 12 inputs; complete equipment 5 seconds / 4 inputs. All use the same seed and policy. This checks that upgrades visibly overpower earlier challenges instead of merely keeping pace with escalating work.

## Native interface and visual iteration
- 189 input/state/layout checks pass over 27 viewport screenshots. These cover the opening, hover help, first purchases, tree exploration, all fifty description layouts, focused Pulse, beams, plating, descent, menus, settings, records, saves, failure recovery and ending. Viewports include 960 × 600, 1440 × 900 and 1920 × 1080.
- A fresh field has one non-board button: Pause. Pulse follows the opening, Grow and currencies follow the first clear; additional tool buttons require ownership.
- An agent played the opening from visible clues using flags and chords, purchased Survey lens, continued to site 2 and purchased Twin pulse. Seventeen harness actions were recorded, including setup and quit. This is additional agent play, not a human session.
- Inspected and corrected crossed tree paths, drone docking over title text, dense plate stripes, an oversized debrief, tooltip grammar, text bounds and backdrop polygon triangulation. The help pages now pair short explanations with animated diagrams.
- Procedural keycaps and the sky gradient are cached by the renderer. The final 180-frame native sample measured roughly 6.9 ms median and 8.4 ms p95 between process frames, with 1,135 draw calls on an RTX 4090. These are machine-specific observations, not minimum hardware claims.

## Assets and packaging
All geometry, textures, icons, music and sound remain procedural and repository-owned. No image/audio generation service or downloaded media was used. Six oscillator-based scores and their synthesis source are retained. In-game engine and library licences remain available.

Both final exports succeed. The actual Windows executable passes its own isolated native boot, rendering, input, tree purchase, save and reload smoke test, with `editor=false`. The Windows archive contains only that executable, its PCK and the player README; each entry is verified against the exported files. Compatibility Web export is provided; browser runtime and persistence have not been validated. Player reports remain local; tests never touch normal saves. Store integration is outside scope.
