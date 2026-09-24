---
title: Travelogue design
type: design
status: skeleton
created: 2026-09-23
updated: 2026-09-23
build: 1.60.1.69913
---

# Travelogue design

How Travelogue is built. What it does, and why, is settled in [DECISION-002](../decisions/DECISION-002-feature-set.md). This doc is a skeleton: the MVP work fills in each section, in the same PR as the code it describes.

The full design, drafted for review before any code, is published as a page: https://claude.ai/artifact/86Mi7PeYJzrsqHSvJbXqEu. It covers the modules, the screenshot capture flow, saved data, chat output, edge cases and build order, and it holds the review answers. Its content moves into this doc as the MVP lands; after that, this doc is the source.

## Layout

Planned, following the [Lua rules](../process/lua.md): pure logic in `Core/`, thin glue outside it.

| File | Holds |
|---|---|
| `Travelogue.toc` | `## Interface: 16001`, `## SavedVariablesPerCharacter: TravelogueCharDB`, ForeverKit embedded |
| `Core/Journal.lua` | Append an entry, mark firsts (`seen`), share one capture between entries that arrive together, archive a journal whose GUID is not the character's |
| `Core/Milestones.lua` | Turn an event payload plus context into an entry, or nothing (a repeat boss, a known map, a failed encounter) |
| `Core/Maps.lua` | Walk a map up to the zone or dungeon it belongs to, given a lookup function (answers Q5 in code) |
| `Core/Shots.lua` | Per-kind policy (delay, UI hidden) and the screenshot file name from a date string and the `screenshotFormat` value |
| `Core/Migrations.lua` | Saved-data steps, from `schemaVersion = 1` |
| `Core/Commands.lua` | Parse `/travelogue` arguments |
| `Locale/enUS.lua` | Every player-facing string |
| `Travelogue.lua` | Glue: events to Core, the capture runner (`C_Timer.After`, hide and restore the UI, `Screenshot`), the slash command, chat output |

Core may not call WoW, so the glue passes in everything from the client: `time()` and `date()` results, map lookups, cvar values.

## Data model

To write: the schema as its first migration spec pins it. [DECISION-002](../decisions/DECISION-002-feature-set.md#journal-model) has the shape.

## Capture flow

To write: event, then entry, then the pending capture and its delay, then UI hidden or not by the combat check, then `Screenshot`, then `SCREENSHOT_STARTED` or `SCREENSHOT_FAILED`, then attaching the file name. Include what happens when a second milestone arrives while a capture is pending, and when `SUCCEEDED` never comes.

## Commands

| Command | Does |
|---|---|
| `/travelogue` | The last entries, newest first |
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
