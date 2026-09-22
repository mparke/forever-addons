# Docs

Research and planning for the Forever addon project. Every doc carries YAML frontmatter with a `build` field naming the beta build its measurements came from; the beta moves, so re-verify anything older than the current build.

## Research

- [Forever Addon Field Guide](research/forever-addon-field-guide.md): the client, the API, secret values, graded beta bugs, tooling, shipping, learning path, open questions. Also published as a page: https://claude.ai/artifact/MJvrKjdTu7P4bXUhZ38zBm
- [Journey-Documenting Addon Landscape](research/journey-addon-landscape.md): auto-screenshot and journal addons that exist today, their status, and the gap.
- [Memento Deep Dive](research/memento-deep-dive.md): source-level read of the one living screenshot addon on Forever and what its Retail code path does on camelot.

## Tasks

- [TASK-001: Define the addon feature set](tasks/TASK-001-define-addon-feature-set.md), status backlog, next up.

## Conventions

- `research/`: findings with sources and evidence grades. Update in place; bump `updated:` and `build:`.
- `tasks/`: numbered `TASK-NNN`, status one of backlog, active, blocked, done.
- `decisions/`: numbered `DECISION-NNN`, created when a task settles something.
