# forever-addons

World of Warcraft: Forever addons (Interface 16001, Mainline API, game type `camelot`). One repo: addons in `addons/`, shared library in `libs/`, specs in `spec/`, tooling in `tools/`, research and rules in `docs/`. Full rules and reasons: `docs/process/`. Decisions: `docs/decisions/`.

## Commands

```
make bootstrap   # once: pinned toolchain into .tools/, git hooks on
make test        # specs only
make check       # what CI runs: fmt-check, lint, typecheck, coverage (90% per file)
make fmt         # format all Lua
```

## Work loop

1. Every change has a GitHub issue. Branch `<issue>-<slug>` from main.
2. Pure logic goes in a `Core/` folder and is written test-first: failing spec in `spec/`, least code to pass, refactor. Core may use only Lua that plain 5.1 also has; lint enforces it.
3. Glue (events, frames, slash commands) stays thin and calls into Core.
4. `make check` green, then a PR with `Closes #N`. Squash-merge with a conventional-commit title (`feat(journal): ...`); it becomes the changelog line.

## Hard rules

- Every global read must exist on Forever: `tools/wow/forever_api.lua` is generated from the pinned beta build and luacheck enforces it. Never add a name to the extras lists in `.luacheckrc` without an in-game `/dump` confirming it.
- An addon writes globals only for its SavedVariables and `SLASH_*` names, declared in its `.luacheckrc` block.
- Published addons follow `docs/process/production.md`: versioned saved data with a spec per migration step, `issecretvalue` before computing on combat values, `InCombatLockdown` before protected work, the performance budget, every player-facing string through the locale table.
- Never hand-edit `tools/wow/forever_api.lua`; bump the pin in `tools/versions` and run `make wow-api`.
- Never `--no-verify` a commit you intend to push.

## Definition of done

Issue acceptance criteria met; specs first for Core; `make check` green locally and in CI; docs updated in the same PR; for a published addon, the relevant in-game checklist items run on the current beta build and noted in the PR.
