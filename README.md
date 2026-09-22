# forever-addons

Addons for **World of Warcraft: Forever** (Interface `16001`), with the tooling that keeps them honest: lint against Forever's real API, type checks against the WoW API annotations, specs with a per-file coverage floor, and a release pipeline to CurseForge.

| Folder | What |
|---|---|
| `addons/` | One folder per addon, exactly what ships |
| `libs/` | Shared library, embedded privately into each addon that uses it |
| `spec/` | busted specs, mirroring the folders above |
| `tools/` | Toolchain bootstrap, checks, the generated Forever API |
| `docs/` | Research, decisions and the process rules |

## Addons

| Addon | Status |
|---|---|
| [HelloForever](addons/HelloForever/) | Sandbox for learning and in-game experiments; not published |
| [ForeverProbe](addons/ForeverProbe/) | Dev-only probe: which APIs exist, which events fire with what, what is secret; not published |

| Library | What |
|---|---|
| [ForeverKit](libs/ForeverKit/) | Saved-data migrations, locale tables, event dispatch; embedded privately into each addon |

## Getting started

From WSL:

```
make bootstrap   # pinned toolchain into .tools/ (no sudo), git hooks on
make check       # everything CI runs
make watch       # copy every save into the Forever beta's AddOns folder
```

Then read [CLAUDE.md](CLAUDE.md) for the work loop and [docs/](docs/README.md) for the rules and research.

## License

[GPL-3.0](LICENSE).
