---
title: Travelogue design
type: design
status: in progress
created: 2026-09-23
updated: 2026-09-25
build: 1.60.1.69913
---

# Travelogue design

How Travelogue is built. What it does, and why, is settled in [DECISION-002](../decisions/DECISION-002-feature-set.md). The MVP work fills in each section, in the same PR as the code it describes. Travelogue is a working name ([review](../decisions/DECISION-002-feature-set.md#design-review-2026-09-25)).

The full design, drafted for review before any code, is published as a page: https://claude.ai/artifact/86Mi7PeYJzrsqHSvJbXqEu. It covers the modules, the screenshot capture flow, saved data, chat output, edge cases and build order. It was approved on 2026-09-25; the answers are recorded in [DECISION-002](../decisions/DECISION-002-feature-set.md#design-review-2026-09-25). Its content moves into this doc as the MVP lands; after that, this doc is the source.

## Layout

Following the [Lua rules](../process/lua.md): pure logic in `Core/`, thin glue outside it. Files marked *planned* arrive in a later MVP PR.

| File | Holds |
|---|---|
| `Travelogue.toc` | `## Interface: 16001`, `## SavedVariablesPerCharacter: TravelogueCharDB`, ForeverKit embedded |
| `Core/Journal.lua` | Claim the journal for the character (archiving another GUID's), append entries, attach a shot to the entries a capture served, mark firsts (`seen`), list the latest |
| `Core/Milestones.lua` (planned) | Turn an event payload plus context into an entry, or nothing (a repeat boss, a known map, a failed encounter) |
| `Core/Maps.lua` (planned) | Walk a map up to the zone or dungeon it belongs to, given a lookup function (answers Q5 in code) |
| `Core/Shots.lua` (planned) | Per-kind policy (delay, UI hidden, none on a taxi for first visits), the screenshot file name from a date string and the `screenshotFormat` value, and the capture state machine that shares one picture between milestones within 2 s |
| `Core/Migrations.lua` | The schema for `Kit.SavedData.load`: version 1, its defaults, no steps yet |
| `Core/Commands.lua` (planned) | Parse `/travelogue` arguments |
| `Locales/enUS.lua` | Every player-facing string, through ForeverKit's `Locale` |
| `Travelogue.lua` (planned) | Glue: events to Core, the capture runner (`C_Timer.After`, hide and restore the UI, `Screenshot`), the slash command, chat output |

Core may not call WoW, so the glue passes in everything from the client: `time()` and `date()` results, map lookups, cvar values.

## Data model

One per-character SavedVariable, `TravelogueCharDB`, loaded through ForeverKit's `SavedData` with the schema in `Core/Migrations.lua`. `spec/Travelogue/Core/Migrations_spec.lua` pins it; the `---@class` annotations there give its types.

```lua
TravelogueCharDB = {
  schemaVersion = 1,
  guid = "Player-1234-0ABCDEF0",       -- the owner, set by Journal.claim at login
  settings = {
    hideUI = true,
    shots = { level = true, achievement = true, boss = true, visit = true, death = false },
  },
  seen = { maps = { [1429] = true }, encounters = { [1084] = true } },
  entries = {                          -- oldest first; append only
    { at = 1793840000, kind = "level", level = 10, map = 1429, zone = "Elwynn Forest", sub = "Goldshire",
      shot = { file = "WoWScrnShot_110426_165322.jpg" } },
  },
  archived = {                         -- earlier owners' journals, oldest first
    -- { guid = "Player-1234-0OLDGUID", entries = { ... }, seen = { ... } },
  },
}
```

- **Kinds:** `start`, `level`, `achievement`, `boss`, `visit`, `death`. Every entry carries `at` (`time()`), `level`, `map`, `zone` and `sub` as read when it was made. The first-visit kind is `visit`, not DECISION-002's `zone`, so it does not collide with the `zone` field.
- **Shots:** `{ file = ... }`, `{ failed = true }` or `{ lost = true }`. `Journal.attachShot` gives each entry its own copy, so one capture serving two entries saves as two small tables, not a shared reference.
- **Deaths** take no picture until the player turns them on (design review).
- **Owner:** `Journal.claim(db, guid)` returns `new` (no owner yet: the GUID is set and anything already there is kept), `same`, or `archived`: another GUID's `entries` and `seen` move to the end of `archived` and a fresh journal starts. `archived` is a list, not DECISION-002's table keyed by GUID, so a GUID archived twice (a character restored after its name was reused) cannot overwrite anything. The glue checks `issecretvalue` before calling `claim`; `claim` refuses anything but a string.
- **Firsts:** `Journal.firstMap` and `Journal.firstEncounter` return true once per id and mark it, so a first survives `/reload`.
- **Load results:** `new` and `reset` start a journal (`reset` says once that the file could not be read). `current` and `migrated` use the data. `failed` and `newer` leave Travelogue off for the session, writing nothing, and `/travelogue` says why.

## Capture flow

To write: event, then entry, then the pending capture and its delay, then UI hidden or not by the combat check, then `Screenshot`, then `SCREENSHOT_STARTED` or `SCREENSHOT_FAILED`, then attaching the file name. Include what happens when a second milestone arrives while a capture is pending, and when `SUCCEEDED` never comes.

## Commands

| Command | Does |
|---|---|
| `/travelogue`, `/trav` | The last 10 entries, newest first; `/travelogue 25` shows up to 50 |
| `/travelogue shots <kind> on\|off` | Screenshots for one kind of milestone |
| `/travelogue hideui on\|off` | Hide the UI for screenshots |

To write: the exact output lines, all through the locale table.

## Testing

To write, per [testing.md](../process/testing.md):

- **Core specs:** every module above, test-first, at or above the coverage floor. That includes a spec per migration step and the capture-sharing window.
- **Glue specs:** through the WoW fake: registration, a level-up producing an entry and a capture request, the combat branch keeping the UI.
- **In game:** the [release checklist](../process/production.md#in-game-release-checklist) plus Travelogue's own items: the UI returns after every capture, including a failed one; a death in combat is recorded; the file-name prediction matches the file in `Screenshots`.

## Performance

To write: measured memory after login with a long journal (target: a level-1-to-60 journey of about 500 entries), against the [budget](../process/production.md#3-performance-budget). No `OnUpdate`; every handler is event-driven.

## Open questions

The probe questions and their answers live in [DECISION-002](../decisions/DECISION-002-feature-set.md#open-questions-for-the-probe). Record here what each answer changed in the design.

The design review's answers are in [DECISION-002](../decisions/DECISION-002-feature-set.md#design-review-2026-09-25). What they changed here: the `/trav` alias, no picture for a first visit made on a taxi, and death pictures off by default.
