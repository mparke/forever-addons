# Releasing

Each published addon has its own version and its own tags, `<Addon>/vX.Y.Z` and `<Addon>/vX.Y.Z-beta.N` ([DECISION-001](../decisions/DECISION-001-repo-foundations.md)). Releases go to CurseForge (flavour Forever) and GitHub Releases.

## Release an addon

From an up-to-date, clean main:

```
tools/release Journal minor      # or major, patch, beta, or an exact 1.4.0 / 1.4.0-beta.2
```

The script refuses an addon without `.pkgmeta`, uncommitted changes, any branch but main, a main that differs from `origin/main`, and a failing `make check`. It then prints the changelog and asks before it tags `Journal/v1.3.0` and pushes the tag. The [release workflow](../../.github/workflows/release.yml) does the rest:

1. checks the tagged commit is on main
2. `make check`
3. `tools/package Journal 1.3.0 --upload`: builds, packages and uploads to CurseForge
4. creates the GitHub Release for the tag with the zip and changelog, marked pre-release for a beta

Watch it under Actions; `tools/release` prints the link.

## Versions

| Bump | From 1.2.3 | From 1.2.3 with 1.3.0-beta.2 tagged |
|---|---|---|
| `patch` | 1.2.4 | 1.2.4 |
| `minor` | 1.3.0 | 1.3.0 (releases the beta line) |
| `major` | 2.0.0 | 2.0.0 |
| `beta` | 1.3.0-beta.1 | 1.3.0-beta.3 |

The first release of an addon bumps from 0.0.0. `tools/version.lua` holds the rules and `spec/tools/version_spec.lua` pins them.

## Changelogs

Built by `tools/changelog` with git-cliff (`cliff.toml`) from the squash titles of commits that touched the addon's folder or a library its TOC embeds. Only `feat` (New), `fix` (Fixed) and `perf` (Faster) appear, so write those titles for players. A release lists everything since the previous release; a beta lists everything since the previous tag of either kind. Preview any time:

```
tools/changelog Journal 1.3.0
```

## How packaging works

`tools/package <Addon> <version> [--upload]` runs the pinned [BigWigs packager](https://github.com/BigWigsMods/packager). The packager treats one git repo as one project and reads the version from the repo's tags, which does not fit a repo of many addons. So `tools/package` builds `.build/<Addon>` (the addon plus its embedded libraries), copies it with the addon's `.pkgmeta` and the generated `CHANGELOG.md` into a throwaway repo under `.release/<Addon>/repo`, tags that with the bare version, and runs the packager there. The packager then substitutes `@project-version@`, comments out `--@debug@` blocks, writes CRLF line endings for Windows players, and zips to `.release/<Addon>/out/<Addon>-<version>-forever.zip`.

Without `--upload` nothing leaves the machine. With it, the script first checks for `CF_API_KEY` and a `## X-Curse-Project-ID` in the TOC, so a release cannot quietly skip CurseForge.

`spec/tools/package_spec.lua` packages `spec/fixtures/PackFixture` on every `make check` and loads the unzipped result in the WoW fake, so a packager or build change that breaks a release fails CI first.

## Rehearse

Locally, nothing uploaded:

```
tools/package Journal 1.3.0
ADDONS_ROOT=spec/fixtures tools/package PackFixture 0.1.0
```

In CI: Actions → release → Run workflow, choose the addon, version and folder. A manual run never uploads; the zip and changelog are kept as a workflow artifact.

## Making an addon publishable

1. Add `addons/<Addon>/.pkgmeta`:

   ```yaml
   package-as: <Addon>
   manual-changelog: CHANGELOG.md
   ```

2. In the TOC: `## Version: @project-version@`, `## X-License: GPL-3.0`, and once the CurseForge project exists, `## X-Curse-Project-ID: <id>`.
3. The production rules in [production.md](production.md) now apply to it, including the in-game release checklist.

## CurseForge, once

1. Create the project in the CurseForge author console: game World of Warcraft, flavour Forever. Note the project ID.
2. Create an API token in the author console's API tokens page.
3. Store it for the workflow: `gh secret set CF_API_KEY -R mparke/forever-addons`, then paste the token.
4. Put the project ID in the addon's TOC as above.

Until both exist, a pushed release tag fails at the package step with a message saying which is missing; nothing is half-released.
