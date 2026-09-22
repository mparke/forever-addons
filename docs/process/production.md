# Production rules

Four hard requirements for every **published** addon. The sandbox (HelloForever) and the probe addon never ship, so they are exempt; the checks in [lua.md](lua.md) still apply to them. Each rule says how it is enforced: by a check, by a spec, or by the in-game checklist at the end.

## 1. Versioned saved data with tested migrations

A bad migration destroys a player's data with no way back, and on the current beta every failed load is followed by a save that overwrites the good file.

- The saved table carries `schemaVersion` (an integer) at its top level.
- Upgrades live in Core as a list of pure functions: step `n` turns a version `n-1` table into version `n`. Never edit a released step; add a new one.
- Each step has a spec with a fixture of the old shape, asserting the new shape.
- A saved `false` survives: merge defaults with `== nil`, never `not value`. Defaults are deep-copied so a table default is never shared with saved data.
- Unknown keys are kept, not deleted: a newer addon version may have written them.
- A table whose `schemaVersion` is newer than the addon knows is left untouched and the addon does not write to it this session (a downgrade must not destroy newer data). Tell the player once.
- Do not build a workaround for the beta's SavedVariables loading bug into shipping code (field guide, section 5). Treat nil at `ADDON_LOADED` as a fresh install.

Enforced by: specs for every step (coverage floor applies to Core); the shared library's saved-data helper.

## 2. Combat safety: secret values and taint

Forever inherits Midnight's secret values in full, plus seven Forever-only restricted APIs.

- Any value from a unit, aura, spell or combat API may be secret. Before arithmetic, comparison, `#`, using it as a table key, or a boolean test on it, check `issecretvalue(v)`. Secrets may be stored, passed to Lua functions, concatenated, formatted, and forwarded to widget methods that accept them (`StatusBar:SetValue`).
- `UnitHealth("player")` is secret in solo open-world combat. Assume nothing is safe because the fight "is not a raid".
- Never call a protected function or touch a protected frame in combat. Check `InCombatLockdown()`; queue the work and run it on `PLAYER_REGEN_ENABLED`.
- Do not call the Forever-only restricted APIs from addon code: `DeleteItem`, `ConfirmDeleteItem`, `ToggleSit`, `CancelAutoRepeatSpell`, `CancelItemTempEnchantment`, `PlaceTargetingSpellAtCursor`, `SetPreferredGamepadInteractTarget`.
- Do not depend on deprecation shims (`loadDeprecationFallbacks`); use `C_*` APIs. Lint already rejects the globals Forever does not load.

Enforced by: review; the in-game checklist with forced restrictions on.

## 3. Performance budget

| Measure | Budget (provisional until first measured) |
|---|---|
| `OnUpdate` | None unless justified in a comment and throttled to at most 10 runs per second |
| Work at login | Only what the first frame needs; defer the rest to after `PLAYER_ENTERING_WORLD` |
| Memory after login | Under 1 MB per addon (`UpdateAddOnMemoryUsage()` then `GetAddOnMemoryUsage(name)`, in KB) |
| CPU | No handler in the addon profiler's top list during normal play (`C_AddOnProfiler.GetAddOnMetric`) |

- React to events; do not poll.
- Register only the events you handle, and unregister one-shot events after use.
- Use `RegisterUnitEvent` for unit events so the client filters them.

Replace the provisional numbers with measured ones after the first published addon's first measurement, and record the change here.

Enforced by: review for the rules; the in-game checklist for the numbers.

## 4. Localization-ready strings

- Every player-facing string goes through the addon's locale table: `L["Screenshot saved"]`, from the first line of code.
- enUS is the base locale and the fallback; a missing key shows the enUS text.
- Build sentences with format strings (`L["Reached level %d"]:format(level)`), never by joining translated fragments, because word order differs between languages.
- Debug output and slash command names are not localized.

Enforced by: review; the shared library's locale helper.

## In-game release checklist

Run before tagging a release, on the current beta build, and paste the results into the release PR or issue with the build number.

- [ ] Clean load: no Lua errors at login or `/reload` (BugSack empty).
- [ ] Saved data: Exit Game, relaunch, confirm what should persist did (read before write). Back up `WTF\Account\<acct>\SavedVariables` first.
- [ ] Migration: load with a saved file from the previous release; data survives.
- [ ] Combat: a fight with `/console addonCombatRestrictionsForced 1` (and the encounter, map and chat variants where relevant) produces no errors or blocked-action messages. Whether these cvars take effect on Forever is unverified; note what you saw.
- [ ] Taint: `/console taintLog 1`, play, check `Logs\taint.log` for the addon's name.
- [ ] Performance: memory after login and the profiler reading against the budget above.
- [ ] Locale: switch to another client locale if available, or check every visible string goes through `L`.
