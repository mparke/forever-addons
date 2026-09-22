# Workflow

How a change goes from idea to main. Decided in [DECISION-001](../decisions/DECISION-001-repo-foundations.md).

## Issues

Every change starts as a GitHub issue in `mparke/forever-addons`.

- **Task** (template "Task"): planned work. Goal, Context, Approach, Acceptance criteria, Open questions. This is the old `docs/tasks/TASK-NNN` shape; issues replaced that folder.
- **Bug** (template "Bug report"): a defect, from you or a player. Addon, version, client build, steps, expected, actual, BugSack output.

Labels:

| Label | Meaning |
|---|---|
| `task`, `bug`, `research` | Kind of work |
| `addon:<Name>` | Which addon it touches (one per addon folder) |
| `lib` | The shared library |
| `tooling` | Toolchain, CI, deploy, release scripts |
| `docs` | Docs only |
| `blocked` | Waiting on something outside the repo, like a beta build or an in-game probe |

Research an issue produces goes in `docs/research/`; a decision it settles goes in `docs/decisions/DECISION-NNN-<slug>.md`. Link both from the issue.

## Branches and PRs

1. Branch from an up-to-date main: `git switch -c <issue>-<slug>`, for example `7-saved-data-migrations`.
2. Work test-first where the code is pure ([testing.md](testing.md)). Commit as often as you like; the pre-commit hook formats and lints what you stage.
3. Push and open a PR whose body says `Closes #<issue>` and fills in the template checklist.
4. CI's `check` job must pass. It is the required status on main.
5. **Squash-merge.** The squash title is a conventional commit and becomes the changelog line, so write it for a player: `feat(journal): record a screenshot at each level-up`.

Main is protected: no direct pushes, no force pushes, admins included. The only way in is a PR with a green `check`.

## Commit titles

[Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`.

- Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`.
- Scope: the addon folder name in lowercase (`helloforever`), `lib`, `tools`, `ci`, or `docs`.
- `feat` and `fix` are what players see in a changelog. Everything else is grouped or hidden.

The release changelog for an addon is built from the squash titles of commits that touched its folder or the shared library ([releasing.md](releasing.md), arriving with the release pipeline).

## Definition of done

A PR is done when:

- [ ] It closes an issue, and meets that issue's acceptance criteria.
- [ ] Pure logic was written test-first and `make check` passes locally and in CI.
- [ ] Docs changed in the same PR: process docs if a rule changed, the addon's README if behaviour changed, a DECISION doc if something was settled.
- [ ] For a published addon: the relevant in-game checklist items from [production.md](production.md) were run on the current beta build, and the PR says which build.
- [ ] The squash title is a conventional commit a player could read.
