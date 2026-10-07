# Working with this user

Lasting preferences, gathered from the agent's memory notes and the session logs, paraphrased and generalised. The game examples show what each one meant in practice. Treat them as the starting assumptions for the next project, and confirm the game-specific ones.

## How they like to work

- **Long autonomous stretches.** The user gives a batch of requests and leaves for hours or overnight. Keep going until the list is done. Checkpoint at feature ends (tick the task list, commit, push) instead of stopping to ask. Never pause a run only to suggest compacting the conversation.
- **In the loop, not babysitting.** They want to try things and decide, not to set up tests. Async playtesting tools exist for this: exported builds, the in-game report button, tuning panels, A/B mode.
- **They decide merges.** Nothing goes into `main` until they've tried it and said so. Branches get pushed freely: they asked for everything to be on the remote, branches and tags included.
- **They try things in the game.** Alternatives are best delivered as switches in a build they can flip, plus a sheet of stills. They like options laid out as **independent axes they can combine** (for a grade display: words or none, which colours, which effects), plus a few curated presets, each fully polished.
- **Questions are questions.** When they ask whether something is possible, or how it works, or where things are stored, they want an answer, and sometimes explicitly no change yet. Offer to build; don't start.
- **Dictated, long, mid-turn messages** with screenshots are normal. Split them into separate requests, record each one, and confirm the reading when it's ambiguous.
- **Ideas to remember, not build.** They sometimes park an idea as off to the side, for later. Record it visibly as parked, and don't build it unless asked.
- **Quality first, even when saving quota.** They accepted cheaper models only for mechanical work. For anything the look or judgement decides, use the strong model.
- **Use what's left.** At the end of their day, leftover quota should be spent on queued work that continues by itself after the reset.

## Reports they want

- **Plain words**, one block per prototype: what it does, what to try (keys), the open questions, and a **ready-to-run launch command in its own code block**, in their shell.
- **Link files, don't attach them** (unless asked). Large media goes as smaller copies when it must be sent to a phone.
- Explain timelines and sequences concretely (for the dynamic music: what plays in the first ten seconds, then what).
- Say what was only scripted and never played by hand.
- Say which build is newest and complete.

## Design taste (this game; generalise as "ask early")

- **Physical, in-world feedback.** Effects come from physical events (an impact, a landing, the crash of the falling log), never from meta timers or floating UI. The smashed set's discs split when the log reaches them, not after a delay. Coins pour onto a heap. Selling is a wooden sign you click, not a HUD button. The fall warning is something in the world. HUD text is a debug readout only.
- **No visible physics cheats.** Nothing may hang frozen in mid-air, sink through solid wood, or clip through the stump. Every freeze, collision exception or pass-through shortcut needs a guard. Test tall and extreme cases (film them).
- **Juice on objects:** squash, hops, glints and sound on the things themselves.
- **Keep the showpiece clean.** The stack of Perfect discs is the thing they like to look at. A new effect is checked on the stack as well as on the tree. When torn bark and a kerf made the stack look worse, it became an off-by-default switch, and sawdust flecks that stay on the tree replaced it.
- **Disliked effects become switches, not deletions.** Default them to off and keep them tunable. Every new effect gets a tuning section with on/off and its main numbers.
- **Freedom over refusals.** "Too steep" and "too thick" refusals were replaced by what the wood would physically do. Any thickness is a valid disc.
- **Accessibility matters.** They care about strain injuries: low-input options that don't feel like cheating (a sticky grab: click to take the axe, click to put it down), and a metric worth optimising in an automated mode.
- **Wary of asset-heavy features.** A village needing art was parked. Procedural content without an asset bottleneck was favoured.

## Their machine is theirs

- They work, and watch videos, on the same computer while agents run. Test windows run hidden and never take focus. Test runs are muted.
- **Never stop processes by name, filter or window title.** Once, a by-name kill sent close requests to the user's open editors of this and another project. Since then: only processes you started, by the exact PID noted at start, and say so in the report. If something is in the way, list the processes and ask.
- Never capture or confine the mouse.
- Keep tool output out of their folders: logs, saves and reports from tests go to the test folder.
- **Downloads and installs need their explicit yes**, per item (fonts were shortlisted with sources, sizes and licences first, then downloaded after approval).
- A denied permission is reported to them, never routed around, for example by giving the same job to another agent.

## Their words and data

- Their messages, bug-report texts and A/B feedback are private. Agents read the feedback only when asked to go through it.
- Nothing they wrote goes into git or onto a published page verbatim. A committed document was checked for runs of eight or more words shared with their messages before it was pushed.
- Their user data found lying in a worktree (A/B answers) was committed only because it belonged in the repo by design. Ask when unsure.
