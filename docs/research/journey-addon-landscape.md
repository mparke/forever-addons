---
title: Journey-Documenting Addon Landscape
type: research
created: 2026-09-22
updated: 2026-09-22
build: 1.60.1.69913
status: current
---

# Journey-Documenting Addon Landscape

Survey of existing addons that document a character's journey, in two categories: automatic screenshots and journals or histories. Compiled 2026-09-22 from CurseForge, Wago and GitHub pages. Status columns are as of that date; every host page was fetched, not inferred.

## Auto-screenshot addons

| Addon | What it captures | Status | Forever |
| --- | --- | --- | --- |
| [Memento](https://www.curseforge.com/wow/addons/memento) | Level-ups, deaths, logins, achievements, boss kills and wipes, PvP, pets, mounts, toys, recipes, loot, timed intervals. Hides the UI out of combat, dedupes boss kills per character. | v2.28, updated 2026-09-18, 85k downloads, source on [GitHub](https://github.com/arcane-wizard-dev/Memento), all rights reserved | Yes. TOC lists 16001. Needs the Arcane Wizard Library. See [[memento-deep-dive]]. |
| [Shotta](https://github.com/martinbjeldbak/Shotta) | Level-ups, boss defeats, intervals, "with friends" moments. MIT, small, 217 commits. | Active, on CurseForge, Wago and WoWInterface | Not declared |
| [Ding!](https://www.curseforge.com/wow/addons/ding-auto-screenshots) | Level-ups, achievements, boss kills, Mythic+, with a delay and a login counter | Updated 2026-03-03, closed source | No, Retail only |
| [lua-wow/screenshots](https://github.com/lua-wow/screenshots) | Achievements, challenge modes, level-ups, deaths. 365 lines, MIT, a reference more than a product | TOC tops out at 11.2 | No |
| [Memoria](https://www.curseforge.com/wow/addons/memoria) | Achievements, level-ups, reputation, PvP outcomes, Mythic+, boss kills; GPLv3 | Abandoned 2023-01-08 | No |
| [Multishot](https://www.curseforge.com/wow/addons/multishot) | Level-ups, achievements, reputation, PvP, rare kills with a boss database; MIT | Abandoned 2015 | No |
| [Level-up Screenshot](https://www.curseforge.com/wow/addons/level-up-screenshot) | `/played` plus a screenshot on every level | Abandoned 2019 | No |

Wyndshots surfaced in search results but its CurseForge and Wago pages both return 404; unverified.

## Journal and history addons

| Addon | What it does | Status |
| --- | --- | --- |
| [MAX Adventure Journal](https://www.curseforge.com/wow/addons/max-adventure-journal) | Records a session and narrates quests, dungeons, companions, loot and deaths as a roleplay chronicle in several prose styles | Updated 2026-08-02, Retail 12.1 and Classic, closed source |
| [AdventureHistory](https://www.curseforge.com/wow/addons/adventurehistory) | Automatic logbook of dungeons, raids and battlegrounds with roster stats and personal notes | Updated 2026-09-01, Retail only |
| [Time Tracker](https://www.curseforge.com/wow/addons/time-tracker) | Playtime per character and account by day, week, month and activity | Updated 2026-09-16, five flavours, not Forever |
| [Character Age](https://www.curseforge.com/wow/addons/character-age) | On-screen `/played`, time on level and level, for streamers | Updated 2025-12-23, Classic only |
| [Adventure Journal 2](https://www.curseforge.com/wow/addons/adventure-journal-2) | Notes, auto-logged quests, zone discoveries, loot, stats | Abandoned 2019, Classic 1.13 |
| [Journal](https://www.curseforge.com/wow/addons/journal) | Free-text travel journal, TotalRP/MyRoleplay extension | Abandoned 2018 |
| [Diary](https://www.curseforge.com/wow/addons/diary) | Money, time played, boss kills, reputation in a diary style | Abandoned 2010 |
| [Timelines](https://www.curseforge.com/wow/addons/timelines) | Questie-based character timeline with level milestones and attunements | Archived 2021, TBC Classic |
| [Chronicles](https://www.curseforge.com/wow/addons/chronicles) | Not a journal: a browsable timeline of Warcraft lore events | Updated 2026-02-11 |

## The gap

Nothing maintained combines the two: a per-character timeline of milestones with the screenshot taken at each one, plus notes. Every journal addon is Retail-only, abandoned, or a roleplay narrator. On Forever specifically, Memento is the only living entry in either category.

## Feasibility on Forever

- `Screenshot()` and `SCREENSHOT_SUCCEEDED` / `SCREENSHOT_FAILED` are documented for Forever 1.60.1 and carry no restriction flags. `screenshotFormat` selects jpeg, png or tga.
- These addons react to events (`PLAYER_LEVEL_UP`, `ACHIEVEMENT_EARNED`, `ENCOUNTER_END`, `PLAYER_DEAD`) rather than reading combat data, so secret values do not touch them.
- The beta's SavedVariables loader bug wipes a journal on every client restart until Blizzard fixes it; build with per-character variables and test with a full exit. See the field guide, section 5.

## Sources

[API Screenshot](https://warcraft.wiki.gg/wiki/API_Screenshot), [SCREENSHOT_SUCCEEDED](https://warcraft.wiki.gg/wiki/SCREENSHOT_SUCCEEDED), plus the host pages linked in the tables.
