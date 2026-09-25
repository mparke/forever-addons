# Docs

Research, decisions and process rules for the Forever addons. Work in flight is tracked in [GitHub Issues](https://github.com/mparke/forever-addons/issues), not here.

Research and decision docs carry YAML frontmatter with a `build` field naming the beta build their measurements came from. The beta moves, so re-verify anything older than the current build.

## Process

How we work. [CLAUDE.md](../CLAUDE.md) is the short version.

- [Workflow](process/workflow.md): issues, branches, PRs, commit titles, definition of done.
- [Lua rules](process/lua.md): layout, Core purity, globals, types, formatting, editor.
- [Testing](process/testing.md): the three layers, the TDD loop, the coverage floor.
- [Production rules](process/production.md): saved data, combat safety, performance, localization, the in-game release checklist.
- [Toolchain](process/toolchain.md): bootstrap, make targets, the hook, upgrading tools.
- [Local loop](process/local-loop.md): build, deploy and watch into the game; safety rules.
- [Releasing](process/releasing.md): versions, changelogs, packaging, CurseForge and GitHub Releases.

## Decisions

- [DECISION-001: Repo foundations](decisions/DECISION-001-repo-foundations.md): topology, quality gates, process, publishing.
- [DECISION-002: Travelogue feature set](decisions/DECISION-002-feature-set.md): the first addon: MVP and later features, journal model, screenshots, saved data, the in-game questions still open.

## Design

- [Travelogue](design/Travelogue.md): how the first addon is built, filled in as each MVP PR lands, with the design review's answers. The full design for review is published as a page: https://claude.ai/artifact/86Mi7PeYJzrsqHSvJbXqEu

## Research

- [Forever Addon Field Guide](research/forever-addon-field-guide.md): the client, the API, secret values, graded beta bugs, tooling, shipping, learning path, open questions. Also published as a page: https://claude.ai/artifact/MJvrKjdTu7P4bXUhZ38zBm
- [Journey-Documenting Addon Landscape](research/journey-addon-landscape.md): auto-screenshot and journal addons that exist today, their status, and the gap.
- [Memento Deep Dive](research/memento-deep-dive.md): source-level read of the one living screenshot addon on Forever and what its Retail code path does on camelot.

## Conventions

- `research/`: findings with sources and evidence grades. Update in place; bump `updated:` and `build:`.
- `decisions/`: numbered `DECISION-NNN-<slug>.md`, created when an issue settles something, linked from that issue.
- `design/`: one `<Addon>.md` per published addon, saying how it is built. Updated in the PR that changes the design.
- `process/`: the rules. A PR that changes how we work changes these in the same PR.
