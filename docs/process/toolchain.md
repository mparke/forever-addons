# Toolchain

Everything runs from WSL with a pinned toolchain in `.tools/` (gitignored). CI installs the same versions with the same script.

## First time

```
make bootstrap
```

`tools/bootstrap` downloads each tool pinned in `tools/versions`, verifies its SHA256, builds Lua 5.1 and LuaRocks from source (no sudo needed), installs the rocks, and points git at `.githooks/`. Re-running it skips anything already at its pinned version. It needs gcc, make, curl, tar and unzip.

| Tool | Used for |
|---|---|
| Lua 5.1.5 (PUC, no readline) | running specs and tools, the same language version as the client |
| LuaRocks | installing busted, luacov, luacheck into `.tools/rocks` |
| busted, luacov | specs and coverage ([testing.md](testing.md)) |
| luacheck | lint against Forever's generated API ([lua.md](lua.md)) |
| StyLua | formatting |
| Lua language server | `make typecheck` and the editor |
| Ketho WoW API annotations | types for the language server |
| git-cliff | per-addon changelogs ([releasing.md](releasing.md)) |
| BigWigs packager (`release.sh`, pinned by commit) | packaging and CurseForge upload |
| BlizzardInterfaceResources (forever branch) | source of `tools/wow/forever_api.lua`, fetched by `make wow-api` |

## Make targets

`make help` lists them. The ones you use daily:

| Target | Does |
|---|---|
| `make check` | everything CI runs: `fmt-check`, `lint`, `typecheck`, `coverage` |
| `make fmt` | format all Lua in place |
| `make test` | specs only, fastest loop |
| `make watch` | copy every change into the game ([local-loop.md](local-loop.md)) |
| `make deploy` | one build and copy |
| `make build` | assemble `.build/<Name>` and verify each TOC, without copying |
| `make wow-api` | regenerate the Forever API lists after bumping the pinned build |

## The pre-commit hook

`.githooks/pre-commit` checks formatting and lint on the staged version of each Lua file, so it judges exactly what you commit. `git commit --no-verify` skips it for a work-in-progress commit; CI will still catch it.

## Upgrading a tool

1. Change its version in `tools/versions` and blank its `*_SHA256`.
2. `make bootstrap` fails with the downloaded checksum. Check it against the publisher's (GitHub shows asset digests on release pages), then pin it.
3. `make check`, fix anything the new version flags, and open a PR (`build(tools): ...`).

CI caches `.tools/` keyed on `tools/versions` and `tools/bootstrap`, so a version change rebuilds it.
