# Delivery state

## Request
Build a polished Minesweeper incremental game with a substantial campaign, qualitative upgrades, full menus/settings/saving, native playtests and visual iteration. Checkpoint to Git regularly. The inherited process notes have been read and adapted.

## Milestones
- [x] Repository conventions, design direction, research.
- [x] Pure board logic, progression, economy and tests: 71,004 checks pass.
- [x] Complete visual game, menus, upgrades, procedural audio and animation.
- [x] Campaign content, save resilience, accessibility and endings.
- [x] Native scripted playtests, screenshots, balance and visual iteration.
- [x] Final regression, packaging documentation, committed delivery.

## Decisions
One integrated delivery branch; no parallel prototype variants. Procedural vector artwork and synthesis avoid an asset bottleneck. Separate test user data and invisible native rendering preserve the shared desktop. Human pacing remains an estimate until externally tested.

All imagery and audio must come from procedural code; do not use image or audio generation services. The current implementation follows that requirement.

## Current verification
71,004 core/persistence checks and 270 native input/state/layout checks pass. Twenty-two captured states were visually reviewed and corrected. An additional opening-field playthrough used only visible clues, flags and chords. Four complete campaign simulations and all twelve trials complete without solver strikes or economic dead ends. A moderate scripted policy estimates 79.6 minutes for the campaign plus 39.2 for mastery (118.8 total); this is a model, not a measured human session.

Standalone Windows and Compatibility Web exports are generated under ignored `builds/`. The Windows release has its own isolated native render/input/save smoke test. Web runtime is unverified. The clean Windows archive contains only the executable, PCK and player README. Full evidence and limits are recorded in `docs/QA.md`.

Delivery is on `codex/afterlight`; gameplay has not been merged into main, respecting the inherited player-review workflow. No store work was performed. All artwork and sound are procedural. Future changes should begin with the player trying this integrated build, rather than creating alternative prototypes.

## Revision 1.1 delivery work
The requested visual and progression revision supersedes the 1.0 sign-off. Implemented: modern retro field terminal, a 6 × 5 opening with staged disclosure, contextual hover help, fifty branching discoveries with animated previews, deeper sites and excavation plating, and exact version-1 save migration.

Current checks: 71,127 core/persistence assertions; 189 native input/state/layout checks; 27 reviewed captures. The native opening was also played from visible clues through the first two purchases. Complete fast campaigns take 175.7 and 173.0 modelled minutes; the three-second policy takes 344.0. All reach fifty discoveries. On an identical test stratum, early/mid/complete equipment requires 100/12/5 seconds. No independent human duration or enjoyment claim is made.

UI and game rules are complete. The new Windows/Web exports, final release smoke, archive and final repository checkpoint are the remaining delivery steps. All art/audio remain procedural. Details: `docs/QA.md`, `docs/DESIGN.md` and `docs/TESTING.md`.
