# Quality record

## Rendering and controls
Godot 4.7.2, Compatibility / OpenGL 3.3, Windows, NVIDIA RTX 4090. Native tests run on a separate invisible desktop with dummy audio and isolated saves.

The first visual pass covered title, fresh field, revealed field, pause, settings, guide, debrief, midgame, aimed crossbeam, atlas, swarm and ending. Found and repaired: Label minimum-width caching caused text overflow; focused mint buttons inherited white text; transient messages obscured modal titles. Upgrade lists now put unowned equipment first.

Tests feed Godot mouse and key input into the actual viewport. Rules tests cover many seeds, flood fill, solver correctness, guaranteed safe starts, completion, purchasing, save roundtrips and backup recovery. Results are scripted playtests; no independent human playtest has been performed.

## Pacing model
Four policy simulations play all 96 fields. The moderate policy makes a decision every seven simulated seconds, uses visible logical deductions, chooses dense covered rows for its beam, and buys affordable available equipment. Drones tick at 0.2-second resolution; menus receive a twelve-second allowance per field. It estimates 79.6 minutes for the campaign and 39.2 minutes for all twelve optional trials, approximately two hours combined. Faster players can finish materially sooner. A learner policy estimates about 100 minutes for the campaign alone.

This measures a synthetic decision policy, not a guarantee of human duration or subjective enjoyment. A manual-only single-cell solver is deliberately inefficient and does not model human chording well.

## Source integrity
All visual art consists of hand-specified geometry, drawing code and deterministic procedural patterns. Music and SFX are synthesized with oscillators and envelopes. No image/audio generation tool was used, and no third-party media was downloaded. Engine and bundled-font notices are available through Credits → Engine & library licences.

## Final verification

- **71,004 rules and persistence checks pass.** Eighty seeded boards exercise logical deductions; fixtures cover dangerous chords, safe tools, trial restrictions, endings, save roundtrips, corrupt-primary recovery and mid-board state.
- **270 native input, state and layout checks pass.** Twenty-two Godot viewport captures cover menu, board, debrief, every guide page, credits, licences, settings, trials, regional transmissions, records, reporting, swarm, ending and failed-save recovery. Window sizes include 960×600, 1440×900 and 1920×1080.
- **Visual decision play:** the agent solved the opening field from visible clues with flags and chords, obtained a perfect rating, bought equipment, paused, returned to the menu and resumed. Twenty-six input actions were recorded. This is additional agent playtesting, not an independent human session.
- **Four complete campaign simulations and all twelve trials pass.** No solver/tool strikes, inaccessible endings or purchase dead ends. Pacing figures above come from these runs.
- **Native performance sample:** 180 rendered late-game frames on the machine above: about 15.1 ms median and 16.0 ms at the 95th percentile between process frames; about 59 MB tracked static memory. These are machine-specific observations, not minimum hardware guarantees. Reusing tile styles preserved the reference frame pixel-for-pixel.
- **Audio:** all six 32-second source WAVs have zero-valued endpoints and peaks below 0.10 full scale. Native tests verify imported duration and the complete 705,600-sample loop boundary; compressed sample byte length must not be used as a frame count.
- **Windows release:** the actual release executable and PCK boot, render, accept input, save and reload, and show licences in the isolated native smoke test. It confirms `editor=false`.
- **Web:** the single-threaded Compatibility export completes successfully. Browser runtime and browser persistence have not been playtested.

Final visual corrections included condensed guide/credits text to prevent footer overlap, consistent dark text on mint focus buttons, a thin energy gauge, and an explicit failed-save quit dialog. Reports and saves from all harnesses stay in ignored test folders.

## Practical limits

No independent human session, controller support, localisation, achievements service, store integration or external distribution has been performed. Two-hour pacing is a content target supported by a simulation, not a guarantee. The native game, campaign, ending, menus and save system are implemented; the standalone build is the delivery for player evaluation.
