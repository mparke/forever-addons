---
title: Forever Addon Field Guide
type: research
created: 2026-09-22
updated: 2026-09-22
build: 1.60.1.69913
status: current
---

# Forever Addon Field Guide

Research compilation for writing World of Warcraft: Forever addons, as of **2026-09-22**. Produced by a ten-agent sweep (six topic researchers, a completeness critic, three gap-fill researchers; roughly 700 page fetches), then compiled and cross-checked by hand. Every claim carries an evidence grade: [primary] means a Blizzard post, a Blizzard API doc file, or Blizzard UI source on the Gethe mirror; [community] means forum posts, addon kits, port PRs, or blogs; [inferred] means reasoning from those. Forever is a moving beta, so every measurement names its build.

## 1. Ten facts that settle everything else

1. **Forever is a third, permanent WoW flavour**, set in the first year of original Azeroth, announced at BlizzCon 2026 on Sept 12, in closed beta from Sept 17 to Oct 21, launching **Nov 4, 2026 at 3:00 p.m. Pacific**. Access is included with any subscription; the paid packs buy cosmetics, the Skyborne race, and (Epic pack and up) beta access. [primary]
2. **It runs the Mainline (Midnight) client, not a Classic client.** `WOW_PROJECT_ID` is `WOW_PROJECT_MAINLINE` (1) and `LE_EXPANSION_LEVEL_CURRENT` is `LE_EXPANSION_CLASSIC` (0). Nora Mills, Lead Software Engineer, at the Sept 17 live Q&A: "We did opt for the modern API approach." [primary for the constants, community for the quote]
3. **The API snapshot is a superset of 12.1.5 PTR, not 12.1.0.** The `forever` branch of Gethe/wow-ui-source (build 69913) carries every 12.1.5-only marker (`C_UnitAuras.GetAuraCasterGUID`, `CreateFrameWithOptions`, `C_Timer.NewTimedSignalMap`, native `math.clamp` / `string.trim` / `table.contains`) plus 20 Forever-only documentation files (SwingTimer, LegacyConsts, GamepadUI, BlizzCon2026, AutoLoot…). Build numbers are global: 69913 sits between PTR 69848 and live 69933. The wiki's "includes Modern changes up to 12.0.7" note is stale. [primary]
4. **The game-type token is `camelot`.** `## Interface: 16001` goes first in any comma list. `AddonName_Camelot.toc` beats `AddonName_Mainline.toc`; `[Game]` expands to `Camelot`; `mainline` in `[AllowLoadGameType …]` is a family covering both `standard` (retail) and `camelot`. There is no `_Forever.toc`; neither the client nor the packager looks for one. [primary]
5. **No runtime constant distinguishes Forever from retail.** Detect it by the interface band (`select(4, GetBuildInfo())` in 16000–16999, as Questie, DBM and Horizon-Suite do) or by a flag file listed only in the Camelot TOC (BigWigs, BetterBags). The retail idiom `interface >= 100000` is false on Forever and sends addons down their Classic branch. [primary]
6. **Secret values apply in full**, and Forever restricts seven APIs that retail does not: `DeleteItem`, `ConfirmDeleteItem`, `ToggleSit`, `CancelAutoRepeatSpell`, `CancelItemTempEnchantment`, `PlaceTargetingSpellAtCursor`, `SetPreferredGamepadInteractTarget`. Your own health is secret in a solo open-world fight. [primary]
7. **Old globals are missing for two mechanical reasons**, both visible in Blizzard's TOCs: `Blizzard_DeprecatedSpecialization` is gated `## AllowLoadGameType: classic, standard` (no camelot), which is why `GetSpecialization`, `GetSpecializationInfo` and `GetTalentInfo` are nil; and every 12.x shim that does load starts with `if not GetCVarBool("loadDeprecationFallbacks") then return end`, a cvar the wiki says can default off in test builds and is never persisted. Never depend on a shim. [primary]
8. **Beta bug: SavedVariables under `WTF\Account` never load on a cold start**, account-wide and per-character alike. Per-character variables are restored across `/reload` within one client run; account-wide ones are not even that. Only `## SavedVariablesMachine` files (top-level `WTF\SavedVariables`) load. Confirmed by many independent testers on 69893 and 69913; not acknowledged by Blizzard as of Sept 22. [community, well corroborated]
9. **Secure snippets are dead on the beta**, and the source explains why: `Blizzard_EnvironmentCleanup.toc` declares its dependency on `Blizzard_RestrictedAddOnEnvironment` with `[AllowLoadGameType classic, standard]`, so on camelot the cleanup nils `loadstring_untainted` before `RestrictedExecution.lua` captures it. Click-casting, state drivers and group headers throw "attempt to call a nil value". Issue forever-bugs #74 proposes the one-word fix. [primary]
10. **The shipping path already works.** The BigWigs packager maps any `16???` interface to game type `forever`, CurseForge has a "Forever" flavour (gameVersionTypeId 88568, version 1.60.1), Wago accepts `supported_forever_patches`, WoWInterface has no Forever at all. The launch-day install folder, Battle.net product code and launch interface number are unannounced. [primary]

## 2. What Blizzard has actually said

Blizzard's news posts about Forever (pre-purchase, BlizzCon round-up, beta-now-live) contain no addon guidance. Everything attributable comes from interviews, the live Q&A, the WoW UI Discord and the beta forum:

| Statement | Who, where, when | Grade |
| --- | --- | --- |
| "We did opt for the modern API approach." Encounters are simpler than Modern, so combat restrictions should not hurt; the team wants one API for authors and does not want players to feel they need addons. | Nora Mills, Lead Software Engineer, WoW Live Q&A, 2026-09-17 (via WoWSoD Pro transcript) | community |
| Forever "shares Mainline WoW's UI architecture, including the vast majority of APIs available in 12.1.5"; Midnight's disarmament changes are active in Forever. | Blizzard UI team on the WoWUIDev Discord, reported by Icy Veins on 2026-09-15/16 | community (Discord not fetchable) |
| The in-combat addon disarmament, "the calculations done to automate marking or communicating for players", carries over; players will not have "computational" addons. | Mike Nuthals, Lead Encounter Designer, to Kotaku, 2026-09-14 | primary |
| Interrupt trackers are "something that we probably are going to make some more changes to, to restrict". | Ion Hazzikostas, Warcraft Tavern interview, 2026-09-14 (page 403s; paraphrased by secondary sites) | community |
| Built-in damage meter and Cooldown Manager ship; "Swing Timer perhaps coming soon." | Nora Mills, same Q&A | community |
| Known issues: "Cooldown Manager is a work in progress. Complete implementation varies from class to class." Nothing about SavedVariables, secure snippets or any addon API. | Kaivax, US forum known-issues thread, 2026-09-17, updated 09-18 | primary |

Not said anywhere: an allow/deny list, the launch folder name, an interface floor for Forever, or any acknowledgement of the SavedVariables loader bug. A built-in quest helper is claimed by one community census and by nobody at Blizzard.

## 3. The client, precisely

**Builds.** 1.60.1.69876 and .69893 (Sept 16), .69913 (Sept 18, still current on Sept 22). Battle.net product `wow_classic_beta`, folder `_classic_beta_`, executable `WowB.exe`. That folder was the MoP Classic beta's in 2025, so stale addons and WTF from it load on first login and throw; disable everything, then re-enable one at a time. wago.tools does not track the product; watch the Gethe `forever` branch's `version.txt` or wowless's `wow_classic_beta/build.yaml` for new builds.

**TOC mechanics that matter on Forever.**

| Mechanism | Behaviour on Forever |
| --- | --- |
| `## Interface:` | Comma list allowed since 10.2.7; older clients stop at the first comma, so the oldest client's number goes first. On Forever that means `16001` first. |
| Suffix precedence | `_Camelot.toc` → `_Mainline.toc` → bare `.toc`. `_Mainline` and `_Classic` are lower priority than every expansion-specific suffix. |
| `[AllowLoadGameType …]` / `[ExcludeLoadGameType …]` per file | Tokens: `standard, mainline, classic, vanilla, tbc, wrath, cata, mists, camelot, plunderstorm, wowlabs, wowhack`. `mainline` = standard + camelot. `standard` = retail only. |
| `## AllowLoadGameType:` header | Same tokens at addon level. Blizzard's own `Blizzard_CooldownViewer.toc` reads `standard, camelot`; `Blizzard_LegacySystem.toc` reads `camelot`. |
| `[Game]` and `[Family]` filename tokens | `[Game]` → `Camelot`; `[Family]` → `Mainline`. Blizzard pairs `[Family]/X.lua [ExcludeLoadGameType camelot]` with `[Game]/X.lua [AllowLoadGameType camelot]` in 48 addons. Copy that when you need a Forever-specific file beside a shared one. |
| Out-of-date handling | The forever branch still ships the "Load out of date AddOns" checkbox wired to `C_AddOns.SetAddonVersionCheck`, and testers use it. Whether the C++ loader enforces any floor on Forever is unmeasured. |

**Systems the namespace advertises but Forever lacks.** Specialisations and hero talents (`GetSpecialization()` is nil; `C_SpecializationInfo.*` exists; spec IDs are new, reportedly paladin 1486), Mythic+, Delves, Housing, the Weekly Vault, Traveler's Log, Warbank (`Enum.BagIndex.AccountBankTab_N` is declared with no bank behind it). The bank is 9 character + 9 account tabs versus retail's 6 + 5. `DefaultPanelFlatTemplate` renders broken; BetterBags switched to `TooltipBorderedFrameTemplate`. Talents are C_Traits-based with camelot-specific ClassTalents files; the account-wide Legacy system is a camelot-only load-on-demand addon unlocking at level 25. `C_CooldownViewer` categories come back empty for Forever specs, so anything built on the Cooldown Manager's data gets nothing. Classic-era events such as `LEARNED_SPELL_IN_TAB` and `CRAFT_SHOW` do not exist, and the old tooltip scripts (`OnTooltipSetItem`, `tooltip:GetItem()`) are replaced by `TooltipDataProcessor` and `TooltipUtil`. Horizon-Suite's conclusion is the right mental model: "Forever ships the full Retail namespace set, so the addon cannot rely on namespace presence alone to detect capabilities."

**Detecting Forever.**

```lua
-- Pattern A: interface band (Questie, DBM, Horizon-Suite). WOW_PROJECT_ID is 1 here, same as retail.
local _, _, _, interfaceVersion = GetBuildInfo()
local isForever = interfaceVersion >= 16000 and interfaceVersion < 17000
local isRetail  = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and interfaceVersion >= 120000
local isRestricted = isRetail or isForever   -- DBM:IsRestricted(): secret-value rules apply

-- The trap: FALSE on Forever (16001 < 100000), so retail code takes its Classic branch.
local looksModern = select(4, GetBuildInfo()) >= 100000

-- Pattern B: a flag file only the Camelot TOC lists (BigWigs Init_[Game].lua, BetterBags core/forever.lua).
-- Init_Camelot.lua, entire file:
local _, tbl = ...
tbl.isForever = true
```

## 4. Secret values: the rulebook Forever inherits

Blizzard's design statement is the frame for everything below: "combat events are in a black box; addons can change the size or shape of the box, and they can paint it a different color, but what they can't do is look inside the box."

**A secret value** is an ordinary Lua value that tainted (addon) code may hold and forward but not inspect. When no restriction is active, secrets behave as plain values.

| From tainted code you may | You may not |
| --- | --- |
| Store in locals, upvalues, table *values*; pass to Lua functions; concatenate; `string.format`; `type()`; truthiness-test a secret string, number or table | Arithmetic; comparisons; truthiness-test a secret *boolean*; `#`; use as a table *key*; index into it; call it; pass it to any C function not marked to accept secrets |

**Regimes.** `Enum.AddOnRestrictionType`: Combat, Encounter, ChallengeMode, PvPMatch, Map, Chat. `ADDON_RESTRICTION_STATE_CHANGED(type, state)` fires *before* a restriction activates (state `Activating`) and *after* it lifts; `C_RestrictedActions.IsAddOnRestrictionActive(type)` returns false during that dispatch. Every guarded API is tagged with a named predicate in Blizzard's docs (`SecretWhenInCombat`, `SecretWhenAurasRestricted`, `SecretOnRestrictedMaps`, `SecretWhenUnitIdentityRestricted`…); those names are the real rulebook. `C_Secrets.*` predicates (`HasSecretRestrictions`, `ShouldAurasBeSecret`, `GetSpellAuraSecrecy(id)`…) tell you *in advance* whether a query would return secrets; the namespace has no comparison helpers, and community docs that claim `C_Secrets.IsLessThan` are fiction.

**Never secret:** your own flagged cooldowns, secondary resources, your own `UnitHealthMax` / `UnitPowerMax`, your own spellcasts, `auraInstanceID`, the five aura booleans `isHelpful` / `isHarmful` / `isRaid` / `isNameplateOnly` / `isFromPlayerOrPlayerPet`, and `SpellCooldownInfo.isEnabled` / `isActive` / `isOnGCD`. Whitelists move between patches in both directions, so ask `C_Secrets` out of combat and branch on `issecretvalue()` at use time rather than hard-coding a spell as safe.

**Widgets that accept secrets** (`AllowedWhenTainted`): `Frame:SetAlpha`, `SetAlphaFromBoolean`, `SetID`; `Region:SetVertexColor(FromBoolean)`; `FontString:SetText`, `SetFormattedText`, `SetTextColor`; `StatusBar:SetValue`, `SetMinMaxValues`, `SetStatusBarColor`. Not accepting from tainted code: `SetShown`, `Show`, `Hide`, `SetScale`, `SetFrameLevel`, `Cooldown:SetCooldown`. Feeding a widget a secret is sticky: it gains a Secret Aspect and the paired getters (`GetText`, `GetValue`, `IsShown`…) return secrets until `SetToDefaults()`.

**The sanctioned display objects.** `C_CurveUtil.CreateCurve()` / `CreateColorCurve()` map a possibly-secret number through addon-defined points; build them at load time from literals, because a curve that ever held a secret point stays poisoned. `C_DurationUtil` Duration objects come out of `C_Spell.GetSpellCooldownDuration(id)` and `C_UnitAuras.GetAuraDuration(unit, instanceID)` and go into `Cooldown:SetCooldownFromDurationObject` or `StatusBar:SetTimerDuration`.

```lua
-- Health bar coloured by a ColorCurve; the addon never sees the number.
local healthCurve = C_CurveUtil.CreateColorCurve()
healthCurve:SetType(Enum.LuaCurveType.Linear)
healthCurve:AddPoint(0.0, CreateColor(0.9, 0.1, 0.1, 1))
healthCurve:AddPoint(0.5, CreateColor(0.9, 0.8, 0.1, 1))
healthCurve:AddPoint(1.0, CreateColor(0.1, 0.8, 0.1, 1))

local bar = CreateFrame("StatusBar", nil, UIParent)
bar:SetMinMaxValues(0, 1)

local function UpdateHealth(unit)
  local pct = UnitHealthPercent(unit, true)          -- maybe secret
  bar:SetValue(pct)                                   -- AllowedWhenTainted
  bar:SetStatusBarColor(healthCurve:EvaluateUnpacked(pct))
  -- DO NOT: if pct < 0.35 then ... end  -> "attempt to compare a secret value" in combat
end
```

**Combat log.** `COMBAT_LOG_EVENT` and `COMBAT_LOG_EVENT_UNFILTERED` are flagged `HasRestrictions` on the forever branch; registering them fires `ADDON_ACTION_FORBIDDEN`. `C_CombatLog` is filter and retention controls only; `C_DamageMeter` is the sanctioned meter source. Libraries from 11.x that register CLEU unconditionally must be guarded.

**Gotchas that bite first.** `if aura.isStealable then` errors in combat (secret boolean); `seen[aura.spellId] = true` errors (secret key), key caches by `auraInstanceID`; SavedVariables may not contain secrets, so scrub before persisting; a frame you once fed a secret keeps returning secrets from `GetText()`; 12.1.5 blocks `Cooldown:SetCooldown` from tainted code on *protected* frames, so hooking Blizzard action-button cooldowns is over; castbar IDs are per unit token and case-sensitive.

**Forcing a regime to test.** The cvars `addonCombatRestrictionsForced`, `addonEncounterRestrictionsForced`, `addonMapRestrictionsForced`, `addonChallengeModeRestrictionsForced` and `addonChatRestrictionsForced` are registered on the 69913 client (wowless dump) and never persist; whether they take effect on Forever has not been reported. `/eventtrace` shows the secret state of payload fields.

## 5. Beta bugs, graded

| Claim | Status on 69913 | Evidence | What to do |
| --- | --- | --- | --- |
| SavedVariables never load on cold start | **CONFIRMED** | Edsdover's two-file repro with NTFS last-access tracking shows the client never *opens* the file; me0wg4ming saved one boolean eight ways, seven came back nil; EU/US threads; forever-bugs #34. Files on disk are correct. Not in Kaivax's known issues. | Test persistence only via Exit Game → relaunch → read before write. Back up `WTF\Account\<acct>\SavedVariables`: every failed load is followed by a save that overwrites the good file with defaults. Do not build a workaround into a shipping addon. |
| `/reload` preserves SavedVariables | **PARTLY** | Careful measurements (imperial64 §P.27, Edsdover, PR #20): account-wide not restored, per-character restored within one client run. Casual reports disagree. | Use `SavedVariablesPerCharacter` for anything you want to demonstrate during the beta. |
| Secure snippets fail to compile | **CONFIRMED** | `loadstring_untainted` is nil at `RestrictedExecution.lua:79`; cause is the `[AllowLoadGameType classic, standard]` dep line in `Blizzard_EnvironmentCleanup.toc`; forever-bugs #74 open, no Blizzard comment. | Guard with `if loadstring_untainted then`; do not build on SecureHandler templates. Blizzard's pre-compiled `SecureActionButtonTemplate` attributes still work. |
| `ReloadUI()` is protected | **NOT FOREVER-SPECIFIC** | The wiki marks `C_UI.Reload` restricted and hardware-event-gated on every flavour including Forever. Single-source claim from the addon kit with no error text. | A Reload button's OnClick from a real click is a hardware event; a timer or chat-driven call is not. Type `/reload`. |
| Error reporting stops after 100 Lua errors | **UNVERIFIED** | Only the forever-addon-kit says so (repeated verbatim by two others). Blizzard's `Blizzard_ScriptErrorsFrame.lua` limit is 1000 and only opens the `TOO_MANY_LUA_ERRORS` popup; BugGrabber throttles at 10 errors/s and stores 500. | Fix error floods first regardless. Install BugSack + !BugGrabber (BugGrabber v12.1.0 declares 16001). |
| Registering an unknown event throws and aborts the file | **NORMAL MAINLINE** | `Frame:RegisterEvent` on an unknown name has thrown since 8.0.1. The Forever twist is which Classic events are absent. | Wrap speculative registrations in `pcall`. |
| Own auras unreadable in combat | **CONFIRMED** | Kit BUG_REPORTS: "Auras cannot be accessed when secret while tainted" for the player's own buffs. Reconciles with §4: display via Duration objects works, reading the data does not. | Fetch Duration objects out of combat and hand them to widgets. |
| Plater aura-container error loop | **CONFIRMED** | `auraContainer:AddAuraGroup()` throws `GetForbiddenObjectTable` at `Blizzard_AuraContainerUtil.lua:319` on every nameplate update (Plater #403). | Any 12.1 AuraContainer code needs `pcall` plus a mark-once. |

Three workarounds for the SavedVariables bug survive a full restart: a symbolic link named `SavedVariablesLink.lua` listed first in the TOC and pointing at the WTF file (must be a symlink, not a copy or hard link, because WoW replaces the file on save); a `!!`-prefixed seed-bridge addon that re-executes copied WTF files (forever-addon-kit `sv_bridge.py`); and macro bodies (255 chars, server-side). `C_CVar.RegisterCVar` is a false workaround: values survive `/reload` but never reach `Config.wtf`. "Exit Now" skips writing `config-cache.wtf`.

## 6. Fundamentals worth internalising on the modern client

- **Folder and TOC.** The folder name and the `.toc` basename must match; files load top to bottom in TOC order; a line starting with `#` in column 0 is a directive or comment. A brand-new folder is discovered at login, not by `/reload`.
- **Load order and lifecycle.** Blizzard addons, then user addons alphabetically (modified by dependencies and LoadOnDemand). Within an addon: files in TOC order, SavedVariables after the last file, then `ADDON_LOADED(name)`. Login sequence: `ADDON_LOADED` per addon → `PLAYER_LOGIN` (once per session, also on `/reload`, never on zoning) → `PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)` (also every loading screen). Logout: `PLAYER_LEAVING_WORLD` → `PLAYER_LOGOUT` (last chance to edit SavedVariables).
- **The namespace vararg.** Every Lua file receives `(addonName, privateTable)`: `local addonName, ns = ...`. XML files do not.
- **SavedVariables.** Global names declared in the TOC; strings, numbers, booleans and non-circular tables only; written on logout, quit and `/reload`. Initialise in `ADDON_LOADED` after comparing the payload to your own name; merge defaults with `db[k] == nil`, never `not db[k]`.
- **Events.** A Frame's `OnEvent` script with `(self, event, ...)`; the dispatch-table idiom `self[event](self, ...)`; `RegisterUnitEvent("UNIT_HEALTH", "player")` to filter; 12.0 added per-event `Frame:RegisterEventCallback(event, fn)` and `RegisterUnitEventCallback`. Frames are never garbage-collected: create once, reuse, `Hide()`.
- **Slash commands.** `SLASH_ID1 = "/x"` plus `SlashCmdList.ID = function(msg, editBox)`; parse with `msg:match("^(%S*)%s*(.-)$")`. Blizzard's commands beat yours; two addons on one ID resolve by load order.
- **Frames.** `CreateFrame(type, name, parent, "TemplateA,TemplateB")`. `SetBackdrop` left plain frames in 9.0.1; inherit `BackdropTemplate`. Anchoring is nine-point `SetPoint`. A movable frame needs `SetMovable(true)`, `EnableMouse(true)`, `RegisterForDrag("LeftButton")`, `StartMoving` / `StopMovingOrSizing`; a globally named frame that is movable before `PLAYER_LOGIN` has its position persisted by the client's layout cache.
- **Options.** The 10.0 `Settings.*` API: `Settings.RegisterVerticalLayoutCategory(name)` or `RegisterCanvasLayoutCategory(frame, name)`, then `Settings.RegisterAddOnCategory`. Since 11.0.2 `Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, variableType, name, default)` binds straight to a SavedVariables table; older examples pass arguments in the wrong slots. `Settings.OpenToCategory(category:GetID())`.
- **Minimap presence.** Three TOC lines (`## AddonCompartmentFunc`, `## IconTexture`) give an Addon Compartment entry with no code; LibDataBroker + LibDBIcon give a draggable minimap button.
- **Edit Mode.** No public registration API; p3lim's LibEditMode is the community answer.
- **Libraries.** LibStub is the version registry every embedded library needs first. Ace3 (AceAddon, AceDB profiles, AceConfig options trees, AceComm) removes boilerplate for settings-heavy addons and is explicitly "not required for writing addons"; plain frames plus the Settings API are right for a small addon.

## 7. Tooling and the local loop

**Editor.** VS Code with `sumneko.lua` and `ketho.wow-api` (0.22.3). The extension auto-activates when any `*.toc` in the workspace has a `## Interface:` line, then writes LuaLS settings (`Lua.runtime.version = "Lua 5.1"`, stock builtins disabled, `Lua.workspace.library` pointing at its annotations). Its annotations are Mainline 12.0.1, the right set for Forever; there is no Forever-specific set. Two traps: VS Code does not merge workspace and user settings, so an empty workspace `Lua.workspace.library` hides the annotations; and the annotation path embeds the extension version, so a hand-written path breaks on update. Annotate the namespace table with `---@class ns` in every file for cross-file typing.

**Lint.** luacheck with `std = "lua51"`, `max_line_length = false`, and a globals whitelist. WeakAuras' and BigWigs' `.luacheckrc` are the reference configs; Jayrgo/wow-luacheckrc is a generated 44k-line Mainline globals list. In CI: `uses: BigWigsMods/luacheck@main`. In WSL, luacheck needs LuaRocks 3 (Ubuntu's apt ships 2).

**Where the repo lives.** Keep the checkout on the NTFS side (`/mnt/c/...`), never under `\\wsl$` (Battle.net enters an infinite update loop), and never as a `.git` folder directly inside `Interface\AddOns` (Battle.net's update check can wedge). Link it in with `cmd.exe /c mklink /J` (a junction; no elevation), because a Linux `ln -s` on DrvFs is not a link Windows follows. Addon managers ignore junctioned folders, which is fine for development. `HelloForever` is set up exactly this way.

**In-game.** `/reload`; `/run <lua>`; `/dump <expr>` (colour-coded, 30 table values); `/fstack` (frame under the cursor; CTRL opens the table inspector); `/etrace` (event trace with secret-state display; `/etrace mark text`); `/tinspect`; `/api`, `/api C_Secrets`, `/api system list` (Blizzard's own API docs, the same data the wiki generates from). All of these are registered on the forever branch and `/dump` and `/run` are confirmed in field reports. `scriptErrors` defaults on in the beta per the wowless cvar dump; `/console scriptErrors 1` otherwise. `taintLog` level 1 explains a blocked action; level 5 logs writes of secret values; levels 2 to 4 are too verbose to leave on. BugSack + !BugGrabber capture stacks; DevTool (`/dev`) still works but its repo was archived on 2026-08-22; TextureAtlasViewer (`/tav`) from CurseForge, not GitHub.

```
/console scriptErrors 1
/console addonCombatRestrictionsForced 1   -- registered on Forever; effect unmeasured; not saved across restarts
/run print(C_Secrets.HasSecretRestrictions(), C_Secrets.ShouldAurasBeSecret())
/run local h = UnitHealth("player"); print(type(h), issecretvalue(h))
/dump HelloForeverCharDB
/api C_Secrets
```

## 8. Shipping

**The packager.** BigWigsMods/packager (`release.sh`; GitHub Action `BigWigsMods/packager@v2`) builds a zip from a git checkout, resolves `.pkgmeta` externals, substitutes `@project-version@` and friends, comments out `--@debug@` / `--@alpha@` blocks, and uploads to CurseForge, Wago, WoWInterface and GitHub Releases. Release type comes from the tag: untagged pushes are alpha; a tag containing "alpha" or "beta" (any case, anywhere) is that type; any other tag is a release. Needs `fetch-depth: 0` and `permissions: contents: write`. Env var names drifted (README says `CF_API_TOKEN`, BigWigs uses `CF_API_KEY`; both work). Keyword blocks are only stripped by the packager, so debug code is live when running from a linked checkout.

**Forever support** landed on 2026-09-17 (PR #202): `16???` → `forever` (alias `camelot`), `## Interface-Camelot:` and `## Interface-Forever:` header lines both accepted, split TOCs written as `_Camelot.toc`, `-g forever` and `-g 1.6x.y` accepted, CurseForge type 88568, Wago `supported_forever_patches` (undocumented on docs.wago.io but live in its API), WoWInterface warned and skipped.

**Two shapes that shipped.** Plater: one TOC with `## Interface: 120100, 120105`, `## Interface-Camelot: 16001`, `## X-Curse-Project-ID`, `## X-Wago-ID`, packaged with `packager@master` and `-S -o`; produced Plater-v656 tagged Forever 1.60.1 on Sept 19. BetterBags: a separate `BetterBags_Camelot.toc` (Interface 16001) whose file list alone includes `core/forever.lua`, packaged with `packager@v2.6.1` and no args. Both auto-detect the flavour from the TOC; neither passes `-g`. Check that a pinned packager tag postdates Sept 17.

```
## Interface: 120100, 120105
## Interface-Mainline: 120100, 120105
## Interface-Camelot: 16001
## Title: MyAddon
## Version: @project-version@
## X-Curse-Project-ID: 100547
## X-Wago-ID: kRNLep6o

MyAddon.lua
```

**Interface floor.** Midnight's rule, sourced to the WoWUIDev Discord, is that Mainline addons below `120000` are refused with no player override. Its scope cannot apply literally to Forever, where 16001 addons load and the out-of-date checkbox is in use. What Forever's own floor is, and whether a launch build at 16002 or 16100 would refuse 16001 addons, is unmeasured and unannounced. The packager will keep classifying any `16???` as forever, and both hosts degrade to the nearest listed version, so the tooling survives a renumbering; a rename of the `_Camelot` suffix or the Battle.net product would not (the packager's filename regex is hard-coded to `Camelot`; Wago already pre-lists `_Forever` spellings).

## 9. Learning path and reference code

1. warcraft.wiki.gg "Create a WoW AddOn in 15 Minutes" (current for 12.x; uses `Settings.OpenToCategory`) and its companion repo ketho-wow/HelloWorld (99-line `Core.lua`; the repo's TOC number is stale, trust the wiki page).
2. The wiki's how-to pages: Using the AddOn namespace, Handling events, Saving variables between game sessions, Creating a slash command, Settings API, Making draggable frames, TOC format (read `?action=raw` when a number matters; a summariser once turned 16001 into 120001).
3. Small models to read: p3lim-wow/Molinari (340-line `addon.lua`, already declares 16001, secure-template and combat-lockdown idioms, per-file game-type gating in the TOC); BugSack; Ketho's tiny utilities (VendorPrice, SimpleDing). lua-wow/screenshots for structure, lua-wow/interrupts as a "what broke and why" study since it depends on CLEU.
4. Porting case studies: kemayo/wow-dropthecheapestthing PR #31 (TOC-only port), Horizon-Suite PR #427 (capability table), BetterBags PR #1092 (Camelot TOC, bank tabs, broken template), Questie PR #7848 (API deltas), DBM's Sept 17–19 commits and BigWigs' single-TOC refactor.
5. Blizzard's source: Gethe/wow-ui-source `forever` branch (the `classic_beta` branch is stale MoP; do not read it) and Ketho/BlizzardInterfaceResources `forever` branch (records `GetBuildInfo()` → "1.60.1", "69913", "Sep 17 2026", 16001). Diff `forever` against `live` to see what differs. Start in `Blizzard_APIDocumentationGenerated` for signatures, then the `Blizzard_*` addon whose UI you want to imitate.
6. Beta-week kits, all to be read as measurements not contracts: Thunderz96/forever-addon-kit (findings table, captured API baseline, porting scripts, three addons), Atraeau/WoW-Addons (30-line HelloForever with a `_Camelot.toc`, `/apiexport` dump, junction-based deploy), imperial64/forever-addon-dev (measured restriction list).
7. Community: WoWUIDev Discord (where the Blizzard UI team posts), WoWInterface's Lua/XML Help forum. YouTube series all predate `C_*` namespaces, the Settings API and secret values; watch for concepts only.

**Lua 5.1 for a TypeScript developer.**

```lua
local t = { "a", "b", "c" }          -- 1-based; #t == 3; holes break # and ipairs
for i, v in ipairs(t) do end          -- ordered, stops at first nil
for k, v in pairs(t) do end           -- unordered, includes string keys
if count == 0 then end                -- 0 and "" are truthy; only nil/false are falsy
local v = cfg.value == nil and default or cfg.value   -- ?? (a and b or c fails when b is false)
local function helper() end          -- everything is global unless you say local
local s = "lvl " .. 60                -- .. concatenates; ~= is not-equal; no +=
local msg = ("%s hit for %d"):format(name, amount)
frame:SetScript("OnEvent", fn)        -- colon passes self; dot does not
local addonName, ns = ...             -- varargs and multiple returns are everywhere
local ver, build, date, toc = GetBuildInfo()
-- no continue: invert the condition. Patterns are not regex: %d %a %s, `-` is lazy, no |, no {n,m}
local cmd, rest = msg:match("^(%S*)%s*(.-)$")
local Base = {}; Base.__index = Base  -- metatables: parent invisible until __index is set
-- sandbox: no io, os, require, dofile. WoW extras: wipe, tContains, strtrim, strsplit, C_Timer.After, bit.band
```

## 10. Open questions to watch before Nov 4

- Launch-day install folder, Battle.net product code and interface number. Nothing named `wow_forever` or `wow_camelot` exists on Battle.net's version server; the wiki's "Forever" and "Forever Test" rows are blank. Watch `us.version.battle.net/v2/summary`.
- Whether Blizzard fixes the SavedVariables loader and the `camelot` dependency gate before launch. Neither is acknowledged.
- Whether the `_Camelot` suffix and `camelot` token get renamed to `forever` at launch (QuestieDB #23 anticipates it; Wago pre-lists both spellings).
- Whether Forever enforces any interface floor, and whether `loadDeprecationFallbacks` defaults on in the beta (`/dump GetCVarBool("loadDeprecationFallbacks")` answers the second).
- Whether the `addon*RestrictionsForced` cvars actually flip secret behaviour on Forever.
- Whether the seven Forever-only `HasRestrictions` flags are documentation or runtime.
- The exact text and author of the Discord "12.1.5 parity" statement, and whether Ketho ships a Forever annotation set.

## 11. Contradictions the sweep surfaced, and how they resolved

- **Does `/reload` preserve SavedVariables?** Sources split. The controlled measurements say account-wide no, per-character yes within one client run; casual reports of success were per-character or fresh-WTF cases.
- **Is `ReloadUI()` protected on Forever?** It is restricted everywhere; the claim is true but not a Forever regression.
- **100 or 1000 errors?** The Lua-side limit is 1000 and only shows a popup; 100 is single-source and unexplained.
- **Unknown events "abort the file".** Standard Mainline behaviour since 8.0.1, not a beta bug.
- **Why are old globals missing?** Three mechanisms were asserted; the branch shows two real ones: a TOC gate on one Deprecated addon, and the cvar guard on every other shim. "Forever ships without wrappers" is the kit's simplification.
- **How to detect Forever.** One result said test `WOW_PROJECT_ID`; that separates Mainline from Classic but not Forever from retail. Interface band or a TOC flag file.
- **Suffix priority.** A summarised wiki list put `_Mainline` first; the raw page says `_Mainline` and `_Classic` are lower priority than every specific suffix.
- **Which 12.x?** Settled by reading the branch: a 12.1.5 superset.
- **Secrets in the open world.** Blizzard's beta matrix says open-world maps apply no *map* regime; the *combat* regime still makes your own health secret in a solo fight, which is what testers observed.
- **Built-in quest helper.** One census says yes; no Blizzard statement; treat as unconfirmed.
- **Own auras in combat.** "Personal displays work" and "own auras throw" are both true: display through Duration objects works, reading the data does not.

## Sources

Blizzard: [pre-purchase and dates](https://news.blizzard.com/en-us/article/24301508/pre-purchase-world-of-warcraft-forever-upgrades-and-begin-your-next-journey-in-azeroth), [BlizzCon round-up](https://news.blizzard.com/en-us/article/24301145/world-of-warcraft-at-blizzcon-2026-discover-whats-next), [beta now live](https://news.blizzard.com/en-us/article/24304160/the-world-of-warcraft-forever-beta-now-live), [Kaivax known issues](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-known-issues-september-18/2352687), [combat philosophy and addon disarmament](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight).
Wiki: [World of Warcraft: Forever](https://warcraft.wiki.gg/wiki/World_of_Warcraft:_Forever), [TOC format](https://warcraft.wiki.gg/wiki/TOC_format), [Secret values](https://warcraft.wiki.gg/wiki/Secret_values), [12.0.0 API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes), [12.0.0 planned changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes), [12.1.0 API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes), [12.1.5 API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes), [AddOn loading process](https://warcraft.wiki.gg/wiki/AddOn_loading_process), [Saving variables](https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions), [Handling events](https://warcraft.wiki.gg/wiki/Handling_events), [Settings API](https://warcraft.wiki.gg/wiki/Settings_API), [Create an AddOn in 15 minutes](https://warcraft.wiki.gg/wiki/Create_a_WoW_AddOn_in_15_Minutes), [C_UI.Reload](https://warcraft.wiki.gg/wiki/API_C_UI.Reload), [CVar loadDeprecationFallbacks](https://warcraft.wiki.gg/wiki/CVar_loadDeprecationFallbacks), [CVar taintLog](https://warcraft.wiki.gg/wiki/CVar_taintLog).
Blizzard UI source: [Gethe/wow-ui-source forever branch](https://github.com/Gethe/wow-ui-source/tree/forever), [Blizzard_EnvironmentCleanup.toc](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_EnvironmentCleanup/Blizzard_EnvironmentCleanup.toc), [Blizzard_DeprecatedSpecialization.toc](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_DeprecatedSpecialization/Blizzard_DeprecatedSpecialization.toc), [Blizzard_ScriptErrorsFrame.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_ScriptErrorsFrame/Blizzard_ScriptErrorsFrame.lua), [Ketho/BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources), [wowless cvar dump](https://raw.githubusercontent.com/wowless/wowless/main/data/products/wow_classic_beta/cvars.yaml).
Interviews and reporting: [WoWSoD Pro Q&A recap](https://wowsod.pro/articles/wow-forever-qa-recap-september-17), [Kotaku](https://kotaku.com/new-things-learned-world-of-warcraft-forever-2000734005), [Game Informer](https://gameinformer.com/blizzcon-2026/2026/09/16/world-of-warcraft-forever-devs-answer-our-biggest-questions-at-blizzcon), [Icy Veins on the Discord statement](https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/), [Windows Central](https://www.windowscentral.com/gaming/blizzard/we-spoke-to-world-of-warcrafts-ion-hazzikostas-on-forever-vs-retail-horde-vs-alliance-and-more).
Beta bugs: [US SavedVariables thread](https://us.forums.blizzard.com/en/wow/t/savedvariables-never-load-in-the-beta-%E2%80%94-all-addon-settings-reset-on-login-69913/2354798), [EU SavedVariables thread](https://eu.forums.blizzard.com/en/wow/t/forever-beta-160169913-savedvariables-fail-to-load-on-client-startupreload-%E2%80%94-all-addon-settings-reset-on-restart/629888), [forever-bugs #34](https://github.com/ClassicWoWCommunity/forever-bugs/issues/34), [forever-bugs #74](https://github.com/ClassicWoWCommunity/forever-bugs/issues/74), [Plater #403](https://github.com/Tercioo/Plater-Nameplates/issues/403), [ForeverSVFix](https://github.com/nobewayo/ForeverSVFix).
Kits and ports: [Thunderz96/forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit), [Atraeau/WoW-Addons](https://github.com/Atraeau/WoW-Addons), [imperial64/forever-addon-dev](https://github.com/imperial64/forever-addon-dev), [kemayo PR #31](https://github.com/kemayo/wow-dropthecheapestthing/pull/31), [Horizon-Suite PR #427](https://github.com/Tacit-Labs/Horizon-Suite/pull/427), [BetterBags PR #1092](https://github.com/Cidan/BetterBags/pull/1092), [Questie PR #7848](https://github.com/Questie/Questie/pull/7848), [BigWigs.toc](https://raw.githubusercontent.com/BigWigsMods/BigWigs/master/BigWigs.toc), [DBM commits](https://github.com/DeadlyBossMods/DeadlyBossMods/commits/master), [Plater.toc](https://raw.githubusercontent.com/Tercioo/Plater-Nameplates/master/Plater.toc), [Molinari](https://github.com/p3lim-wow/Molinari), [ketho-wow/HelloWorld](https://github.com/ketho-wow/HelloWorld).
Tooling and hosts: [Ketho/vscode-wow-api](https://github.com/Ketho/vscode-wow-api), [BigWigsMods/packager](https://github.com/BigWigsMods/packager), [packager PR #202](https://github.com/BigWigsMods/packager/pull/202), [BigWigsMods/luacheck](https://github.com/BigWigsMods/luacheck), [CurseForge Forever filter](https://www.curseforge.com/wow/search?class=addons&page=1&pageSize=20&sortBy=latest+update&gameVersionTypeId=88568), [Wago game data](https://addons.wago.io/api/data/game), [Battle.net version summary](https://us.version.battle.net/v2/summary), [delink.dev on symlinks](https://delink.dev/2023/11/windows-symlinks-and-how-they-help-with-wow-addon-development/), [handynotes WSL setup](https://raw.githubusercontent.com/wiki/zarillion/handynotes-plugins/Setup-with-WSL.md), [wow4ever addons](https://wow4ever.quest/en/addons), [BugSack](https://github.com/funkydude/BugSack).
