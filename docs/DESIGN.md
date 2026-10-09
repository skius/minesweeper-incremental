# Afterlight — design contract

## Experience
An abandoned planetary survey network wakes up one patch of land at a time. The player reads Minesweeper clues, harvests light, builds tools, and gradually teaches a fleet to do the fieldwork. A modern Windows 95/XP-inspired field terminal gives the game a tactile identity: raised slate keycaps, periwinkle title bars, inset LED counters and a procedural evening desktop. The board is the visual centre; effects originate on its tiles.

## Rules and progression
- Left click reveals; right click flags; click a satisfied clue to chord. Keyboard arrows, Space and F offer full board control.
- First reveal clears a safe neighbourhood. Zero cells propagate. Clue numbers never lie. Flagging earns nothing until verified, preventing farming.
- Mines damage the expedition rating and break a chain, but never erase currency, upgrades, or explored tiles. Every expedition remains completable.
- Free rechargeable probe guarantees a way through ambiguous boards. Optional drones only make logically valid deductions; late Oracle probes resolve stalemates.
- Six regions, sixteen sites each, with 628 deterministic strata, authored relay endings, region rules and twelve optional mastery trials. An ending gives way to endless expeditions.
- Unlocks change verbs: probes, lenses, safe crosses, row sweeps, auto-flags, chain chording, logical drones, drone fleets, oracle resolution and overdrive.
- Credits fund equipment. Research cores from expedition completions gate major capabilities. The economy must support several build orders without mandatory grinding.
- Perfect play earns mastery stars. Stars unlock cosmetic fleet liveries rather than gating the campaign.
- Target content duration: approximately three hours for a fast player, before optional mastery trials, varying with puzzle skill and automation choices. Measure actions and simulated pacing; do not claim human duration was verified without human sessions.

## Unfolding and power
- A fresh game shows a 6 × 5 field and Pause. Pulse appears after the first opening; currencies and Grow appear after the first clear. Equipment controls exist only when owned. Atlas appears after the first region.
- After the first Lens purchase, one core buys either Crossbeam or Scout immediately. The next clear can fund the other. The tree shows only owned nodes and reachable nodes at the current milestone.
- The old permanent shop and regional sidebar are gone. Hover reveals clue/tool information. The separate zoomable tree reveals nearby nodes as connections are acquired; descriptions and animated demonstrations are contextual.
- Fifty nodes form six branching routes from a central lens: beams, fleet, energy, craft, discovery and alchemy. Prerequisites and site milestones govern discovery; resources govern purchase order. Branches are not mutually exclusive.
- Buried plates begin at site 7. Deductions remain classic Minesweeper; a proved-safe plated tile still needs excavation. Manual drilling, fleet chassis and bore lasers break multiple layers. Pulses always penetrate their safe target.
- Sites deepen from one stratum into up to thirteen. From site 7, strata alternate wide shelves, tall shafts and square geodes, with coherent plate seams or clustered islands and pockets. Dimensions stay within 26 × 18. Terrain uses its own deterministic random streams and never changes clue arithmetic. Old saves keep their original board generation. Upgrades eventually overpower old work; a fixed-stratum benchmark checks this directly.
- Field zoom, an overview and keyboard following preserve legibility in small windows. Energy uses the same symbol on storage and tool costs; a selected footprint previews its actual price, including recycling. Upgrade demonstrations are recorded from real miniature game sessions.
- Optional trials keep the first pair familiar, then scale into dense shafts, shelves and geodes with up to six plating layers. Survey trials park active beams and drones while keeping passive discoveries; fleet trials showcase the complete toolkit. Each is one board, and existing trial saves keep their stored layout.
- New late-game behavior includes autonomous descent, eight-drone overdrive, row-and-column beams, 7 × 7 bursts and chain carryover. Site transitions still belong to the player. No real-time waiting gate is used to manufacture campaign length.

## Presentation

The field, currency display and equipment dock share a horizontal centre axis. The dock sits sixteen logical pixels below the field, with separate icon and price rows and at least eight pixels between tool controls. Mounted symbols respond within their own bounds. Resource totals appear by the currency display so they cannot obscure clues. The optional field legend (button or L) uses the actual installed Pulse glyph, corner crystals and metal plate layers, and shows only encountered concepts.
Readable clues take precedence over effects. Reveals have a staggered lift, mint edge glints, musical intervals and travelling resource motes. Flags spring into place. Abilities trace geometric paths. Completion produces a board-wide light wave and a brief celebratory chord. Upgrades visibly add or change a tool or drone.

## Research applied
- [Nodebuster, developer's store description](https://store.steampowered.com/app/3107330/Nodebuster/): reference for an explorable upgrade tree, not copied visuals or code.
- Anthony Pecorella, [Quest for Progress, GDC Europe 2016](https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf): model capable purchase decisions and make power growth visible. Applied through fast policies, multiple build priorities and an identical-stratum power comparison.
- Martin Jonasson / Petri Purho, [Juice It or Lose It, GDC Europe 2012](https://gdcvault.com/play/1016487/Juice-It-or-Lose): layered response to simple actions. Application: movement, sound and reward motion coordinated around reveals.
- Jan Willem Nijman, [The Art of Screenshake](https://www.youtube.com/watch?v=AJdEqssNZ-U), also described by the [conference organiser](https://www.control-online.nl/2013/10/18/kort-vlambeers-jan-willem-nijman-spreekt-over-the-art-of-screenshake/): numerous small responses accumulate into game feel. Application: tile-local recoil with optional restrained board shake, rather than constant camera movement. The video itself was unavailable to the research tool; no claim of watching it.
- [Progressive Mine Sweep](https://github.com/lepouya/progressive-mine-sweep): broad genre inspiration only. No code or assets copied.
- [Godot Compatibility renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html): native and future web use the same 2D rendering path.

## Scope boundary
Single-player, offline, one save profile with backup, no monetisation, networking, Steam API, accounts or external dependencies. Art, music and SFX are generated from code. No mandatory real-time waiting.
