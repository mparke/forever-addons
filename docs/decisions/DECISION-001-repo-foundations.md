---
id: DECISION-001
title: Repo foundations, process, quality gates and publishing
type: decision
status: accepted
date: 2026-09-22
build: 1.60.1.69913
---

# DECISION-001: Repo foundations, process, quality gates and publishing

Settled in one Q&A session on 2026-09-22, before any addon beyond HelloForever existed. The process docs in `docs/process/` say how each decision is carried out; this doc records what was chosen and why.

## Topology

| Decision | Choice | Why |
|---|---|---|
| Where the code lives | One repo in WSL (`~/projects/wow-addons`), all addons, shared code, docs and tooling together | Lint, tests and git run at native Linux speed on the same OS as CI; file watching works; research and code live side by side. |
| Getting code into the game | A deploy step copies each addon into `Interface\AddOns`; a watch mode copies on save | A junction cannot point into `\\wsl$`, and a checkout under `\\wsl$` sends Battle.net into an update loop. Copying also ships only runtime files, and one config can target the beta folder now and the launch folder later. Cost: a dead watcher means stale code in game. |
| Hosting | Public GitHub, `mparke/forever-addons` | Addons ship as readable Lua anyway; public gives unlimited Actions minutes and a source link for players. |
| Game versions | Forever only (Interface 16001, game type `camelot`) | One API surface for the fakes and the lint lists. Retail is the same API family if it is ever wanted. |
| What the repo holds | Published addons, one shared in-house library, HelloForever as an unpublished sandbox, a dev-only probe addon | The library holds the code every addon needs (saved-data migrations, events, locale), which is also the most testable layer. The sandbox and probe are for in-game experiments and never ship. |
| HelloForever migration | Fresh copy into `addons/HelloForever`, no history; the old Windows repo is left untouched | Its three commits are not worth a history rewrite. |

## Lua quality and testing

| Decision | Choice | Why |
|---|---|---|
| Required checks | luacheck, StyLua, Lua language server type check, per-file coverage floor | Each catches a different class: unknown globals, style noise, wrong API types, untested logic. |
| Where checks block | Pre-commit hook (format and lint of staged Lua) plus CI (`make check`) as a required status on main | The hook is fast feedback; CI cannot be skipped. |
| Testing model | Pure Core logic written test-first with busted on real Lua 5.1; thin event and frame glue tested against a WoW API fake; an in-game checklist for what cannot be faked (secret values, taint, event order, saved-data loading) | Most addon logic can be pure and fully tested; the rest is honest about its limits. |
| Toolchain | Pinned versions with checksums in `tools/versions`, installed into `.tools/` by `tools/bootstrap`, the same script in CI | No sudo needed, nothing drifts between machines, upgrades are one-line diffs. |

Refinements made while building step 1, within those decisions:

- **Lint against Forever's real API.** `tools/wow/forever_api.lua` is generated from Ketho/BlizzardInterfaceResources' `forever` branch at a pinned commit and build. luacheck loads it, so a global Forever lacks (`GetSpecialization`) or a missing `C_*` field fails lint even though Retail has it. The generated file is committed so a build bump shows up as a reviewable API diff.
- **Core purity is enforced, not just advised.** Files under any `Core/` folder get the `wow_core` standard: only the Lua functions WoW and plain Lua 5.1 share. A WoW API call in Core fails lint.
- **Coverage is per file, and an unloaded file counts as 0%**, so a new module with no spec cannot slip under the floor. Floor: 90% for `libs/` and every `Core/` folder.
- **Actions are pinned by commit SHA.**

## Production rules

All four are hard requirements for published addons from day one: versioned saved data with tested migrations; combat safety (secret values and taint); a performance budget; localization-ready strings. The sandbox and the probe are exempt because they never ship; the checks still apply to them. Details and how each is verified: `docs/process/production.md`.

## Process

| Decision | Choice | Why |
|---|---|---|
| Changes to main | One branch and PR per issue, squash-merged with a conventional-commit title; main protected against direct pushes, admins included | The squash title is the changelog line. |
| Work tracking | GitHub Issues for everything, with task and bug templates | One place online; players can file bugs there too. TASK-001 became an issue and `docs/tasks/` was removed. |
| Knowledge | Research in `docs/research/`, decisions in `docs/decisions/`, each linked from the issue that produced it | Issues are for work in flight; decisions need to be findable later. |
| Rulebook | `docs/process/` holds the full rules and reasons; a short `CLAUDE.md` holds commands, the TDD loop, hard rules and the definition of done, linking to the process docs | Each rule written once. |
| License | GPL-3.0 for everything, one LICENSE at the root | Keeps forks open; the library is unlikely to be embedded elsewhere. |

## Publishing

| Decision | Choice | Why |
|---|---|---|
| Versioning | Independent semver per addon, tags `<addon>/vX.Y.Z` | Releasing one addon does not touch the others. |
| Trigger | `tools/release <addon> <major\|minor\|patch\|beta>`: changelog from the addon's own commits (git-cliff, path-filtered), tag, push; CI packages and uploads | Explicit and few moving parts. |
| Destinations | CurseForge (flavour Forever) and GitHub Releases; no Wago, no per-merge alpha builds | |

## Deviation to confirm with the user

The shared library was proposed as "versioned with LibStub". While designing it, private embedding looked better: each addon loads its own copy into its own namespace, with no global and no LibStub. With independently versioned addons, LibStub would make every addon run against the newest library copy any of them shipped, a version it was never tested with. Private copies mean each addon runs exactly the library it was tested with, and add no globals. Recorded here so the choice is visible; revisit if two addons ever need to share library state.

## Consequences

- Nothing works in game until it is deployed; the old junction must be removed first or the copy writes through it into the Windows repo.
- The generated API and the WoW fake are only as good as the pinned build; bumping `WOW_RESOURCES_COMMIT` is part of reacting to a new beta build.
- A CurseForge project and API token are needed before the first real release.
