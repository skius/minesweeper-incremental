# Afterlight — design contract

## Experience
An abandoned planetary survey network wakes up one patch of land at a time. The player reads Minesweeper clues, harvests light, builds tools, and gradually teaches a fleet to do the fieldwork. Warm ivory, ink blue, sea glass, coral and technical cartography give the game a calm, tactile identity. The board is the visual centre; effects originate on its tiles.

## Rules and progression
- Left click reveals; right click flags; click a satisfied clue to chord. Keyboard arrows, Space and F offer full board control.
- First reveal clears a safe neighbourhood. Zero cells propagate. Clue numbers never lie. Flagging earns nothing until verified, preventing farming.
- Mines damage the expedition rating and break a chain, but never erase currency, upgrades, or explored tiles. Every expedition remains completable.
- Free rechargeable probe guarantees a way through ambiguous boards. Optional drones only make logically valid deductions; late Oracle probes resolve stalemates.
- Six regions, sixteen expeditions each, with fixed campaign seeds, authored transmissions, region rules and twelve optional mastery trials. An ending gives way to endless expeditions.
- Unlocks change verbs: probes, lenses, safe crosses, row sweeps, auto-flags, chain chording, logical drones, drone fleets, oracle resolution and overdrive.
- Credits fund equipment. Research cores from expedition completions gate major capabilities. The economy must support several build orders without mandatory grinding.
- Perfect play earns mastery stars. Stars unlock cosmetic fleet liveries rather than gating the campaign.
- Target campaign duration: approximately two hours, varying with puzzle skill and automation choices. Measure actions and simulated pacing; do not claim human duration was verified without human sessions.

## Presentation
Readable clues take precedence over effects. Reveals have a staggered lift, mint edge glints, musical intervals and travelling resource motes. Flags spring into place. Abilities trace geometric paths. Completion produces a board-wide light wave and a brief celebratory chord. Upgrades visibly add or change a tool or drone.

## Research applied
- Martin Jonasson / Petri Purho, [Juice It or Lose It, GDC Europe 2012](https://gdcvault.com/play/1016487/Juice-It-or-Lose): layered response to simple actions. Application: movement, sound and reward motion coordinated around reveals.
- Jan Willem Nijman, [The Art of Screenshake](https://www.youtube.com/watch?v=AJdEqssNZ-U), also described by the [conference organiser](https://www.control-online.nl/2013/10/18/kort-vlambeers-jan-willem-nijman-spreekt-over-the-art-of-screenshake/): numerous small responses accumulate into game feel. Application: tile-local recoil with optional restrained board shake, rather than constant camera movement. The video itself was unavailable to the research tool; no claim of watching it.
- [Progressive Mine Sweep](https://github.com/lepouya/progressive-mine-sweep): broad genre inspiration only. No code or assets copied.
- [Godot Compatibility renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html): native and future web use the same 2D rendering path.

## Scope boundary
Single-player, offline, one save profile with backup, no monetisation, networking, Steam API, accounts or external dependencies. Art, music and SFX are generated from code. No mandatory real-time waiting.
