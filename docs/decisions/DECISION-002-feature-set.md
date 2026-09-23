---
id: DECISION-002
title: Travelogue, the first addon - feature set, journal model, screenshots and saved data
type: decision
status: proposed
date: 2026-09-23
build: 1.60.1.69913
---

# DECISION-002: Travelogue feature set

Settles TASK-001 ([#1](https://github.com/mparke/forever-addons/issues/1)). What exists on Forever was checked three ways:

- **API presence** against `tools/wow/forever_api.lua`, generated from the pinned build 69913.
- **Payloads and secrecy flags** from Blizzard's API documentation on the Gethe `forever` branch. That branch is at build 69977, published 2026-09-23, one build newer than the pin.
- **Behaviour** from Blizzard's own UI code on that branch.

Whatever only the game can answer is listed under [Open questions](#open-questions-for-the-probe) with the exact command to run.

## The addon

**Travelogue** keeps a timeline of each character's journey through Forever (levels, new zones, first boss kills, achievements and deaths) and takes a screenshot at every milestone.

It fills the gap the [landscape survey](../research/journey-addon-landscape.md) found. No maintained addon combines a per-character milestone timeline with the screenshot taken at each milestone. On Forever the only living addon in either category is Memento, which takes screenshots but keeps no journal.

"Travelogue" is a working name. No WoW addon by that name turned up on 2026-09-23. "Keepsake" was the first choice, but a 2016 screenshot addon already has it. Confirm the name before creating the CurseForge project.

## Features

### MVP

| Feature | Trigger (payload used) | APIs | Screenshot |
|---|---|---|---|
| Journey start | `PLAYER_LOGIN` with an empty journal | `UnitGUID`, `UnitClass`, `UnitRace`, `UnitLevel` | no |
| Level-up | `PLAYER_LEVEL_UP` (`level`) | none beyond the context below | yes |
| Achievement, including Legacy Challenges | `ACHIEVEMENT_EARNED` (`achievementID`, `alreadyEarned`) | `GetAchievementInfo`; `C_Traits.GetTraitCurrencyForAchievement(Constants.LegacyConsts.LEGACY_POINTS_TRAIT_CURRENCY_ID, id)` for Legacy points | yes, unless `alreadyEarned` |
| First kill of each boss | `ENCOUNTER_END` (`encounterID`, `encounterName`, `difficultyID`, `groupSize`, `success`) | `GetInstanceInfo` | yes |
| First visit to each zone and dungeon | `ZONE_CHANGED_NEW_AREA`; `PLAYER_ENTERING_WORLD` (`isInitialLogin`, `isReloadingUi`) | `C_Map.GetBestMapForUnit`, `C_Map.GetMapInfo` | yes |
| Death | `PLAYER_DEAD` | none beyond the context below | yes |
| Context on every entry | none; read when the entry is made | `time`, `UnitLevel`, `GetZoneText`, `GetSubZoneText`, `C_Map.GetBestMapForUnit` | |
| Screenshot at each milestone | `SCREENSHOT_STARTED`, `SCREENSHOT_SUCCEEDED`, `SCREENSHOT_FAILED` | `Screenshot`, `UIParent`, `InCombatLockdown`, `C_Timer.After`, `C_CVar.GetCVar`, `date`, `time` | |
| Journal in chat, and toggles | `/travelogue` | `SlashCmdList` | |

**How each name was verified.**

- Every event is in the `events` list of `forever_api.lua`, and every function is in its `api`, `framexml`, `frames` or `lua` list.
- `SlashCmdList` is in the lint extras, with evidence from game build 69913.
- `Constants` is in the `tables` list, and `LegacyConsts` is documented in `LegacyConstantsDocumentation.lua`: `LEGACY_POINTS_TRAIT_CURRENCY_ID = 4225`, `LEGACY_REWARD_TRACK_FACTION_ID = 2802`.

**Secret values.**

- None of these events has a secrecy flag on its payload in the Forever docs.
- Of the functions, only `UnitGUID`, `UnitClass` and `UnitRace` can return secrets, and only when unit identity is restricted (`SecretWhenUnitIdentityRestricted`). Travelogue reads them once at login and checks `issecretvalue` before using them.
- `Screenshot` carries no restriction flag.
- Nothing reads combat data.

**Whether each subsystem runs on Forever.**

- **Levels, zones, deaths and screenshots** are client events with no Blizzard UI addon in front of them.
- **Achievements.** `Blizzard_AchievementUI` is gated `mainline, tbc, wrath, cata, mists`, and `mainline` includes camelot. `Blizzard_LegacySystem` is camelot-only and depends on it.
- **Legacy Challenges are achievements.** This is from Blizzard's own code, so it is primary evidence:
  - `Blizzard_LegacyChallenges.lua` registers `ACHIEVEMENT_EARNED` and reads its first argument as the completed challenge's id.
  - Challenges are listed with `GetAchievementInfo(categoryID, index)`.
  - The Legacy points a challenge awards come from `C_Traits.GetTraitCurrencyForAchievement(4225, achievementID)`.
  - So the achievement feature covers Legacy Challenges, and records their points, with no separate event. A non-zero point value marks an achievement as a Legacy Challenge. The probe confirms it in play (Q1).
- **Boss kills.** `Blizzard_EncounterJournal` is gated `standard, classic`, so the Encounter Journal does not load on Forever. `ENCOUNTER_END` does not depend on it, but nobody has measured whether Forever's 2004 dungeons run their bosses as encounters (Q4). If they do not, boss kills move to Later and `BOSS_KILL` gets a look.

### Later

| Feature | Trigger and APIs | Why not in the MVP |
|---|---|---|
| Timeline window | `CreateScrollBoxListLinearView`, `ScrollUtil.InitScrollBoxListWithScrollBar`, `CreateDataProvider` (all in `framexml`) | Capture has to be right on launch day. A window added later still shows everything captured before it existed. Next after the MVP. |
| Settings panel | Blizzard's `Settings` API | `Settings` is not in `forever_api.lua`; it needs a lint extra with evidence first. The MVP uses slash toggles. |
| Notes on entries | none | Needs the window. |
| The player's own screenshots in the journal | `SCREENSHOT_SUCCEEDED` with no capture pending | Depends on Q3. |
| Legacy rank-ups | `MAJOR_FACTION_RENOWN_LEVEL_CHANGED` (`majorFactionID` 2802, `newRenownLevel`, `oldRenownLevel`) | Blizzard shows "Legacy points" as the renown level of faction 2802, which is account-wide. It belongs in an account timeline, and the event is unmeasured (Q2). |
| Time played at each level | `RequestTimePlayed`, `TIME_PLAYED_MSG` (`totalTimePlayed`, `timePlayedThisLevel`) | The request prints to chat, and suppressing that is its own piece of work. |
| First mount | `NEW_MOUNT_ADDED` (`mountID`) | `Blizzard_Collections` loads on the `mainline` family, but nobody has measured whether the event fires. |
| Profession and reputation milestones | `SKILL_LINES_CHANGED`, `UPDATE_FACTION` | Needs thresholds worth recording. |
| Hardcore deaths | `C_GameRules.IsHardcoreActive`, `HARDCORE_DEATHS` (`memberName`) | No Forever hardcore ruleset has been announced (Q8). |
| All characters in one timeline | account-wide SavedVariables | On the beta, account-wide variables do not survive even `/reload`. |

### Out of scope

- Export.
- Sharing.
- Roleplay addon integration (TotalRP, MyRoleplay).
- Other WoW flavours.
- Reading or processing screenshot files: addons cannot touch the filesystem.
- Logging every quest. It is noise; `QUEST_TURNED_IN` is there if a curated list is ever wanted.

## Journal model

| Decision | Choice | Why |
|---|---|---|
| Whose journal | One per character | The journey is the character's. An account timeline comes later. |
| Keying | One per-character SavedVariable holding the owning character's GUID. If the GUID at login differs, the old journal moves to `archived[<old guid>]` and a new one starts. | A deleted character recreated with the same name and realm would otherwise inherit the old file. |
| Order | Append-only array, oldest first. An entry is only changed to attach its screenshot. | A journal that is only appended to cannot lose history to a bug in editing. |
| Names | Stored as shown at capture, with the ids beside them | The journal reads correctly even if an id stops resolving; ids allow re-localising later. |
| Time | `time()`, epoch seconds from the client clock | The client names screenshot files from the same clock. |
| Firsts | `seen.maps[uiMapID]` and `seen.encounters[encounterID]` | Cheap dedupe that survives `/reload`. |

```lua
-- Client clock in US Pacific: the first entry is launch, 2026-11-04 15:00. A shot is
-- taken the capture delay after its entry, so its file name is a second or two later.
TravelogueCharDB = {
  schemaVersion = 1,
  guid = "Player-1234-0ABCDEF0",
  settings = { hideUI = true, shots = { level = true, achievement = true, boss = true, zone = true, death = true } },
  seen = { maps = { [1429] = true }, encounters = {} },
  entries = {
    { at = 1793833200, kind = "start", level = 1, class = "WARRIOR", race = "Human", map = 425, zone = "Northshire", sub = "" },
    { at = 1793836912, kind = "level", level = 2, map = 1429, zone = "Elwynn Forest", sub = "Northshire Valley",
      shot = { file = "WoWScrnShot_110426_160153.jpg" } },
    { at = 1793840000, kind = "achievement", id = 6, name = "Level 10", legacyPoints = 0, level = 10, map = 1429,
      zone = "Elwynn Forest", sub = "Goldshire", shot = { file = "WoWScrnShot_110426_165322.jpg" } },
  },
  archived = {},
}
```

## Screenshots

| Decision | Choice | Why |
|---|---|---|
| One capture per moment | Entries within 2 seconds of each other share one capture | Level 10 and the "Level 10" achievement fire together; one picture serves both. |
| UI | Hidden for levels, bosses, zones and deaths; shown for achievements | For an achievement, the toast is the picture. |
| In combat | The UI stays up | Hiding `UIParent` in combat touches protected frames. This is Memento's rule. |
| Safety | `pcall` around hide and capture, with a guaranteed `UIParent:Show()` | A failed capture must never leave the player without a UI. |
| Delay | Level 1.0 s, achievement 1.5 s, boss 1.5 s, zone 3.0 s, death 0.5 s | Lets the level-up glow, the toast, the loot and the loading screen settle. Tune in play. |
| Linking the file | Note `time()` at `SCREENSHOT_STARTED`, or at the call if that event never comes. On `SUCCEEDED`, record `WoWScrnShot_MMDDYY_HHMMSS.<ext>`, with the extension taken from the `screenshotFormat` cvar (`jpeg` gives `jpg`). On `FAILED`, record the failure. | The addon cannot list files, so it predicts the name. It can be a second off; the window will say "around". Q3 checks the format. |
| Screenshots the player takes | Ignored in the MVP. A `SUCCEEDED` with no capture pending attaches to nothing. | Keeps the player's own shots from landing on the wrong entry. |
| Player control | `/travelogue shots <kind> on\|off`, `/travelogue hideui on\|off` | The settings panel comes later. |

## Saved data

| Decision | Choice | Why |
|---|---|---|
| Variables | `## SavedVariablesPerCharacter: TravelogueCharDB` only; the MVP's settings live in the same table | The journal is per character. Per-character is also the only kind that survives `/reload` on the beta, so it is the only kind development can exercise. |
| Versioning | ForeverKit `SavedData` from `schemaVersion = 1`; every [production rule](../process/production.md) applies | Travelogue is a published addon. |
| During the beta | Test persistence with `/reload` only. Before any client restart you care about, back up `WTF\Account\<acct>\<realm>\<character>\SavedVariables\Travelogue.lua`. | A restart loses the journal. The client never reads the file, the addon sees nil and starts fresh, and logout writes the empty journal over the good file. |
| Workarounds | None in the addon; no public release while the bug stands | Production rule 1. A release now would wipe every tester's journal on each restart. |
| At launch | On day one, run the honest test on the launch build: Exit Game, relaunch, `/travelogue` before anything writes. If the journal is there, nothing changes. | Blizzard has not acknowledged the bug; the launch build is the first chance to see a fix. |
| If launch still fails | Move the journal to `## SavedVariablesMachine`, the one kind that loads on 69913, keyed by character GUID. Do it with a migration step and a new DECISION. | At that point it is no longer a beta workaround but the only storage that works. The cost: that file sits in the top-level `WTF\SavedVariables` and is shared by every account on the PC, so the GUID key keeps characters apart. |

## Open questions for the probe

Run these with ForeverProbe ([README](../../addons/ForeverProbe/README.md)) on the current beta build. Post the output, with `/dump GetBuildInfo()`, to the Travelogue MVP issue.

| # | Question | Commands | Decides |
|---|---|---|---|
| Q1 | Does completing a Legacy Challenge fire `ACHIEVEMENT_EARNED`? Blizzard's code says yes. | `/probe watch ACHIEVEMENT_EARNED`, complete a Legacy Challenge, `/probe log`. Then `/dump C_Traits.GetTraitCurrencyForAchievement(4225, <id from the log>)`: expect more than 0, and 0 for an ordinary achievement. | Legacy Challenges ride on the achievement feature, told apart by their point value. |
| Q2 | What fires when Legacy points go up? | `/probe watch MAJOR_FACTION_RENOWN_LEVEL_CHANGED`, `/probe watch TRAIT_TREE_CURRENCY_INFO_UPDATED`, `/probe watch CURRENCY_DISPLAY_UPDATE`, complete a Legacy Challenge, `/probe log`. `/dump C_MajorFactions.GetCurrentRenownLevel(2802)` before and after. | The trigger for Legacy rank-ups (Later). |
| Q3 | Does `SCREENSHOT_SUCCEEDED` fire for screenshots the player takes? What exactly is the file named? | `/probe watch SCREENSHOT_STARTED`, `/probe watch SCREENSHOT_SUCCEEDED`, `/probe watch SCREENSHOT_FAILED`, press Print Screen, then `/run Screenshot()`, `/probe log`. Compare the new file names in `_classic_beta_\Screenshots` with the time of each capture; `/dump C_CVar.GetCVar("screenshotFormat")`. | The file-name rule; whether players' own screenshots can join the journal (Later). |
| Q4 | Do Forever's dungeon bosses fire `ENCOUNTER_END`? | `/probe watch ENCOUNTER_END`, `/probe watch BOSS_KILL`, kill a dungeon boss, `/probe log` | Whether boss kills stay in the MVP. |
| Q5 | What map does the client report in the open world, in a city and in a dungeon? | `/dump C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))` in each place, and `/probe watch ZONE_CHANGED_NEW_AREA` while crossing a zone border | How a subzone or dungeon floor is walked up to the zone or dungeon it belongs to. |
| Q6 | Does hiding the UI around a timed screenshot work out of combat? | `/run UIParent:Hide() C_Timer.After(0.1, Screenshot) C_Timer.After(0.3, function() UIParent:Show() end)` | The capture sequence. |
| Q7 | Are the character's identity, level and zone readable at login and in combat? | `/dump UnitGUID("player"), issecretvalue(UnitGUID("player")), UnitLevel("player")`. Then `/run C_Timer.After(5, function() print(issecretvalue(UnitLevel("player")), issecretvalue(GetZoneText())) end)` and start a fight within 5 seconds. | Whether a death in combat can carry level and zone. |
| Q8 | Does Forever have a hardcore ruleset? | `/dump C_GameRules.IsHardcoreActive()` on each realm type offered | Hardcore deaths (Later). |
| Q9 | At launch: is the client still 16001, and what is the install folder called? | `/dump GetBuildInfo()` (the fourth value), and look at the folder name | TOC and deploy config; nothing in the feature set. |

## Consequences

- Boss kills leave the MVP if Q4 comes back empty.
- A settings panel needs `Settings` added to the lint extras, with evidence, before it can be written.
- Build 69977 is on the Gethe `forever` branch. Bumping the pin (`make wow-api`) is its own issue. This decision's API names were checked on 69913, and the payloads were read on 69977.
- The design lives in [docs/design/Travelogue.md](../design/Travelogue.md). It starts as a skeleton and is filled in by the MVP work.
