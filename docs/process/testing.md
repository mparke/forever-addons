# Testing

Three layers, from most code to least:

| Layer | What | How | Gate |
|---|---|---|---|
| Pure Core | Data models, rules, migrations, formatting: anything that can take its inputs as arguments | busted on real Lua 5.1, written test-first | per-file coverage floor, 90% |
| Glue | Event handlers, frames, slash commands | busted against a fake of the WoW API that rejects names Forever does not have | specs where the fake is honest |
| In game | Secret values, taint, real event order and payloads, saved data across a real restart | the probe addon and the checklist in [production.md](production.md) | run before a release, recorded in the PR |

## The TDD loop

1. Write the spec for the next behaviour in `spec/<Name>/...`. Run `make test`; watch it fail for the right reason.
2. Write the least code in `Core/` that passes.
3. Refactor with the spec green. `make check` before pushing.

Name specs `*_spec.lua`. One `describe` per module, one `it` per behaviour, phrased as the behaviour: `it("keeps a saved false instead of replacing it with the default")`.

## Coverage

`make coverage` runs the specs with luacov and fails if any file under `libs/` or any `Core/` folder is below 90% of lines (`COVERAGE_FLOOR` in the Makefile). A file in scope that no spec loads counts as 0%. Glue outside Core is not counted: coverage there would reward testing the fake.

## What the fake does not prove

A spec passing against the fake means the logic is right given the fake's assumptions. It says nothing about which values the client really makes secret and when (the fake makes a value secret only when a spec says so), taint, combat lockdown, the real order of events at login, or whether saved variables load on this beta build. Those are the in-game checklist's job.

## The harness: `spec/support/wow.lua`

A fake of the Forever client built from `tools/wow/forever_api.lua`, strict where the client is strict:

- Reading a global Forever does not define is an error (`GetSpecialization is not defined on Forever`), not a nil.
- A frame has exactly the methods its widget type has on Forever, following inheritance. Calling one it lacks fails as it would in game.
- `RegisterEvent` refuses an event Forever does not know, with the client's own message.
- Secret values (`wow:secret(n)`) error on arithmetic, comparison, length and indexing, and allow concatenation and `tostring`; `issecretvalue` recognises them.
- A Forever global the fake has not implemented yet is an error that says so. Implement it in `wow.lua` (with `provide`, which refuses names Forever lacks) when a spec needs it.

Pure Core code:

```lua
local Wow = require("support.wow")
local SavedData = Wow.loadCore("libs/ForeverKit/Core/SavedData.lua").Kit.SavedData
```

`loadCore` runs the file with only the Lua both WoW and plain 5.1 have, so a WoW API call in Core fails at runtime as well as in lint.

Glue and whole addons:

```lua
local wow = Wow.new({ level = 12, health = 80 })        -- player state, all optional
local ns = wow:loadAddon("MyAddon", { saved = { MyAddonDB = { schemaVersion = 1 } } })
wow:fire("PLAYER_LOGIN")
wow.state.health = wow:secret(40)                       -- combat: health goes secret
wow:fire("UNIT_HEALTH", "player")
wow:slash("/my status")
assert.are.same({ "..." }, wow.printed)                 -- print output
assert.are.same({}, wow.errors)                         -- errors sent to the error handler
assert.is_nil(next(wow.written))                        -- globals the addon wrote
```

`loadAddon` does what the client does: the TOC's files in order (XML `Script`/`Include` expanded in place) sharing one namespace, then the saved variables, then `ADDON_LOADED`. `Libs/<Lib>/` paths are found in `libs/` when the addon does not carry them, so no build is needed. `wow:loadFile(path, name, ns)` runs a single glue file.

Known gaps, which the in-game checklist covers: `type()` of a secret is `"userdata"`, not the underlying type; no taint and no combat lockdown enforcement; events fire only when a spec fires them, not in the client's real order.
