# Travelogue

A journal of each character's journey through World of Warcraft: Forever, with a screenshot at every milestone: levels, achievements including Legacy Challenges, first boss kills, first visits to zones and dungeons, and deaths.

**Travelogue is a working name.** It will be replaced before the CurseForge project is created.

In development under [#11](https://github.com/mparke/forever-addons/issues/11); not released. What it does and why: [DECISION-002](../../docs/decisions/DECISION-002-feature-set.md). How it is built: [the design](../../docs/design/Travelogue.md).

## Commands

Planned, and arriving with the glue: `/travelogue` (also `/trav`) lists the latest entries. `/travelogue shots <kind> on|off` and `/travelogue hideui on|off` change what is captured.

## Saved data

One per-character table, `TravelogueCharDB`, versioned from `schemaVersion = 1`. On the beta, SavedVariables do not load after a client restart, so test with `/reload` only and back up the file before restarting.
