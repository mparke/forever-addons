# Lua rules and the checks that enforce them

WoW runs Lua 5.1 with Blizzard's additions and removals. Everything here is checked by `make check`; the pre-commit hook runs formatting and lint on what you stage.

## Layout of an addon

```
addons/<Name>/
  <Name>.toc          Interface 16001 first; lists every file in load order
  Core/               pure logic: no WoW API, fully tested off the client
  *.lua               glue: events, frames, slash commands, calling into Core
  Locales/            player-facing strings (production.md)
spec/<Name>/          busted specs, mirroring the addon's folders
```

Every file starts with `local ADDON_NAME, ns = ...`. WoW passes the folder name and one private table shared by all the addon's files; that table is the only way files share code. There is no `require` in an addon.

## Core purity

Anything in a `Core/` folder, in an addon or in `libs/`, gets luacheck's `wow_core` standard: only the Lua functions that both the WoW client and plain Lua 5.1 have (`tools/wow/forever_api.lua`, list `portable`). A call to `CreateFrame`, `strsplit` or any WoW API from Core fails lint. The payoff: Core code runs the same in game and under busted, so it can be written test-first and covered to the floor.

Core receives what it needs from the WoW API as arguments. Glue reads the API and passes values in.

## Globals

- An addon defines globals only for what the client requires to be global: SavedVariables and `SLASH_<NAME><n>`. Each addon lists these in its own `files[...]` block in `.luacheckrc`; anything else it writes to `_G` fails lint.
- Reading a global fails lint unless Forever's client defines it. The lists come from the pinned beta build, so a Retail-only API fails even though the annotations know it. When Blizzard ships a new beta build, bump `WOW_RESOURCES_COMMIT` and `WOW_RESOURCES_BUILD` in `tools/versions`, run `make wow-api`, and read the diff of `tools/wow/forever_api.lua`: that diff is the API change.
- A global the client sets as a variable rather than a function (`WOW_PROJECT_ID`, `SlashCmdList`) is not in the generated lists. Add it to `extraReadGlobals` or `extraGlobals` in `.luacheckrc` and to `tools/wow/annotations/extras.lua`, only after confirming it exists on Forever in game (`/dump NAME`).

## Types

`make typecheck` runs the Lua language server over the repo with Ketho's WoW API annotations (Mainline 12.0.1, the right family for Forever) plus `tools/wow/annotations/`. It catches wrong argument types, missing methods and nil misuse. Annotate what the server cannot infer:

- saved tables and other shapes with `---@class` and `---@field`
- the namespace in each file with `---@class <Name>NS` when it grows members other files use

Warnings fail the check. Fix the code or the annotation; do not add `---@diagnostic disable` without a comment saying why.

## Formatting

StyLua (`stylua.toml`): 2 spaces, 120 columns, double quotes, parentheses on every call. `make fmt` formats everything; never hand-format.

## Editor

VS Code, remote into WSL, with `sumneko.lua`. `.luarc.json` points the language server at the same pinned annotations CI uses (`.tools/wow-api`), so run `make bootstrap` once before opening the folder. The `ketho.wow-api` extension is optional: `.luarc.json` takes precedence over the settings it writes.
