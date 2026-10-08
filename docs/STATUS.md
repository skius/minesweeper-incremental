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

## Revision 1.1 in progress
Player feedback supersedes the original visual/content sign-off: reduce screen text and choices, introduce concepts gradually, build a radial branching tree with 50 meaningful discoveries, target roughly three hours using faster player models, and establish a modern Windows 95/XP-inspired identity. No scanline readability penalty; geometry and synthesized audio only.

Core implementation now adds strata, visible excavation plating, 26 additional discoveries and version-1 save migration. New pacing policies make one-second decisions and use aimed beams and chording. UI is being replaced with a quiet field window and a separate upgrade map; full native/visual validation and new release packaging remain outstanding. Previous 1.0 pacing/visual claims do not validate this revision.
