---
title: Memento Deep Dive
type: research
created: 2026-09-22
updated: 2026-09-23
build: 1.60.1.69913
subject: arcane-wizard-dev/Memento v2.28 (commit 809021b, 2026-09-18)
status: current
---

# Memento Deep Dive

Source-level read of [Memento](https://github.com/arcane-wizard-dev/Memento) v2.28 and its dependency [Arcane Wizard: Library](https://github.com/arcane-wizard-dev/Library) v1.34, cross-checked against Blizzard's Forever API documentation on the Gethe mirror (`forever` branch, build 69913) and Ketho's Forever API dump. Both repos were cloned and read; nothing here comes from a host page summary.

## Headline

Memento contains no Forever-specific code. Its Forever support in v2.28 is one number added to `## Interface`. On Forever it runs its Retail code path unchanged, because the library detects flavour with `WOW_PROJECT_ID`, which reports Mainline on Forever. That path works, with several options that can never fire and a few cosmetic wrong turns. The changelog says so itself: "initial test version for World of Warcraft: Forever. Some addon features may not work correctly yet."

## What the repo is

- **Size and shape.** 2,391 lines of Lua. `Memento.lua` holds the event handlers and registration; `core/Capture.lua` the screenshot itself; `core/Options.lua` the Settings API panel; `common/Utils.lua` profiles, SavedVariables and chat output; `data/*` constants and the in-game changelog. XML files only list load order.
- **Dependency.** `ArcaneWizardLibrary` (5,641 lines) supplies flavour constants, the options-panel builder, minimap button, changelog window, and bundles LibStub, CallbackHandler, LibDataBroker and LibDBIcon.
- **License.** All rights reserved (2024–2026 Arcane Wizard). Read it for idioms; do not copy code. Sounds are separately licensed per `assets/sounds.md`.
- **Release.** BigWigs packager via a shared org workflow (`release_blueprint.yml`), `.release-config/pkgmeta.yaml` with `required-dependencies: arcane-wizard-library`, manual `CHANGELOG.md`.
- **SavedVariables.** `Memento_Options_v6` (account-wide, with per-character profiles keyed by GUID inside it) and `Memento_DataBossKill` (per character). `## LoadSavedVariablesFirst: 1`.
- **The v2.28 diff** (Sept 18): `16001` inserted into `## Interface`; an `isInitialized` guard on the slash command; `AbortInitialization` when the character GUID is unavailable at `ADDON_LOADED`; profile keys moved from realm-name to GUID.

## How it works

1. One frame, `MementoFrame`, with `OnEvent` dispatching `self[event](self, event, ...)`.
2. Each handler checks its option flag, then calls `Capture:ScheduleTimer(handlerName, delay, ...)`, which is `C_Timer.After` into a named-handler table. Delays are per event, plus a 0.1s offset.
3. `TakeScreenshot()`: if "hide UI" is on and `InCombatLockdown()` is false, wrap in `pcall`: `UIParent:Hide()`, show a small timestamp frame, `C_Timer.After(0.1, Screenshot)`, `C_Timer.After(0.2, UIParent:Show)`. On any error, restore the UI and take a normal screenshot. In combat, screenshot with UI.
4. Sound: `PlaySoundFile` for bundled mp3s, falling back to `PlaySound(SOUNDKIT[...])`, each in `pcall`.
5. Boss kills: `ENCOUNTER_END` with `GetDifficultyInfo(difficultyID)` to classify party/raid/scenario; dedupe in `Memento_DataBossKill[difficulty][encounterID]` when "first kill only" is set.
6. Loot: `SHOW_LOOT_TOAST`; item quality via `C_Item.GetItemQualityByID`, retried five times with `C_Item.RequestLoadItemDataByID` when the item is not cached.
7. Time played: `RequestTimePlayed()` at load, `TIME_PLAYED_MSG` seeds totals, then `GetTime()` deltas keep them current so a level-up can print time on the previous level.

Nothing reads combat data, so secret values never touch it.

## What the Mainline path does on Forever

Every event it registers exists in Blizzard's Forever docs, so no `RegisterEvent` throws and the file loads completely. Whether each can fire depends on the subsystem's TOC gate on the `forever` branch.

| Event registered on Forever | In Forever docs | Can fire on Forever |
| --- | --- | --- |
| `PLAYER_LEVEL_UP`, `PLAYER_DEAD`, `PLAYER_ENTERING_WORLD`, `TIME_PLAYED_MSG`, `DUEL_FINISHED`, `NEW_RECIPE_LEARNED`, `ADDON_LOADED` | yes | yes |
| `ACHIEVEMENT_EARNED`, `CRITERIA_EARNED` | yes | yes. Forever's Legacy system is built on achievements: `Blizzard_LegacySystem` is camelot-only and depends on `Blizzard_AchievementUI`, which loads for the `mainline` family. Whether every Legacy Challenge fires the event is unmeasured. |
| `ENCOUNTER_END` | yes | yes. Payload (`encounterID, encounterName, difficultyID, groupSize, success, encounterUnitStatus`) has no secrecy predicate. |
| `PVP_MATCH_COMPLETE` | yes | yes for battlegrounds. `Blizzard_PVPMatch` is `standard, camelot`. `winner` is a plain number. Arena and brawl branches depend on content Forever may not have. |
| `NEW_PET_ADDED`, `NEW_MOUNT_ADDED`, `NEW_TOY_ADDED` | yes | probably. `Blizzard_Collections` loads for `mainline`. |
| `SHOW_LOOT_TOAST` | yes | unmeasured |
| `CHALLENGE_MODE_COMPLETED` | yes | never. `Blizzard_ChallengesUI` is `standard, mists`. The Mythic+ option still appears in the settings. |
| `NEW_HOUSING_ITEM_ACQUIRED` | yes | never. `Blizzard_HousingDashboard` is `standard` only. The housing option still appears. |

Functions it calls, all present on Forever (Blizzard docs or Ketho's `GlobalAPI.lua` / `FrameXML.lua` dump), none with `HasRestrictions` or a secrecy predicate: `Screenshot`, `RequestTimePlayed`, `GetDifficultyInfo`, `C_PvP.IsArena` / `IsBattleground` / `IsSoloRBG` / `IsInBrawl`, `C_Item.GetItemQualityByID`, `C_Item.RequestLoadItemDataByID`, `GetAchievementInfo`, `GetAchievementLink`, `PlaySoundFile`, `PlaySound`, `GetMoneyString` (FrameXML Lua), `UnitFactionGroup`, `IsInInstance`, `InCombatLockdown`, `GetServerTime`, `GetTime`, `C_AddOns.GetAddOnMetadata`.

**Cosmetic wrong turns.** The library's About panel labels the flavour "Retail". Level-up chat text uses the Retail wording. The settings panel shows Retail-only sections (Mythic+, Housing, Arena, Brawl) because `GAME_TYPE_MAINLINE` is true.

**Beta caveat.** `Memento_Options_v6` is account-wide, so on the current beta its settings reset on every client restart and are not restored across `/reload` either. `Memento_DataBossKill` survives `/reload` but not a restart. That is the client's SavedVariables loader bug, not Memento's.

## Forever-only APIs Memento does not use

Blizzard's Forever docs add `C_SwingTimer` (`PLAYER_SWING`, `PLAYER_SWING_RANGE_UPDATE`), `C_AutoLoot`, `C_LootFrame`, `C_GamepadTargeting`, and a `LegacyConsts` table: `LEGACY_REWARD_TRACK_FACTION_ID = 2802`, `LEGACY_POINTS_TRAIT_CURRENCY_ID = 4225`, `LEGACY_TREE_PROFESSIONS_ID = 1187`, `LEGACY_TREE_ADVENTURE_ID = 1188`, `LEGACY_TREE_PROGRESSION_ID = 1189`. There is no `C_Legacy` namespace; the Legacy system is achievements plus `C_Traits` trees plus a currency and a reputation track. For a journey addon, Legacy Challenge completions are the Forever-specific milestone worth capturing. Blizzard's own code settles how, on the `forever` branch at build 69977 [primary]:

- **Challenges are achievements.** `Blizzard_LegacyChallenges.lua` registers `ACHIEVEMENT_EARNED` and reads its first argument as the challenge's id.
- **Points per challenge** come from `C_Traits.GetTraitCurrencyForAchievement(4225, achievementID)`.
- **The "Legacy points" the UI shows** are not a plain currency. They are the renown level of faction 2802: `C_MajorFactions.GetCurrentRenownLevel(Constants.LegacyConsts.LEGACY_REWARD_TRACK_FACTION_ID)`.

Whether the events fire in play is still unmeasured. [DECISION-002](../decisions/DECISION-002-feature-set.md#open-questions-for-the-probe) lists the probe commands.

## What a Forever-aware fork would change

- Detect Forever by interface band or a `_Camelot.toc` flag file, then hide the Mythic+, Housing, Arena and Brawl options and skip those registrations.
- Use `SavedVariablesPerCharacter` for anything that must survive `/reload` during the beta.
- Label the flavour correctly and use the Classic level-up wording.

## Idioms worth borrowing

- Named-handler table plus `C_Timer.After` for delayed captures: options stay serialisable and the timer carries only a string and args.
- `pcall` around the UI-hide sequence with a guaranteed restore path.
- Per-difficulty, per-encounter dedupe table in per-character SavedVariables.
- Item-data retry loop for loot toasts.

## Sources

[Memento](https://github.com/arcane-wizard-dev/Memento) (commit 809021b), [Arcane Wizard Library](https://github.com/arcane-wizard-dev/Library), [Forever API docs](https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated), [Ketho Forever resources](https://github.com/Ketho/BlizzardInterfaceResources/tree/forever/Resources), [Blizzard Watch on the Legacy system](https://blizzardwatch.com/2026/09/12/first-look-wow-forevers-legacy-system/), [Wowhead Forever achievements](https://www.wowhead.com/forever/achievements).
