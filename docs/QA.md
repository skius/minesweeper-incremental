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

## Remaining delivery checks
Expanded interaction regression (keyboard focus, trial return, settings, reports, resizing), final visual inspection and native release export smoke test.
