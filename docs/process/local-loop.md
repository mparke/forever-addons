# Local loop: build, deploy, watch

The code lives in WSL; the game reads `Interface\AddOns` on Windows. A copy step connects them ([DECISION-001](../decisions/DECISION-001-repo-foundations.md)).

## Daily use

```
make watch      # leave running: every save is in the game within a second
```

Then in game, `/reload`. Watch prints each change it copies:

```
16:49:56  HelloForever:
  HelloForever.lua
```

A failed build (a TOC naming a missing file) is reported once and nothing is copied until it is fixed. Watch polls once a second rather than using inotify: the copy of an unchanged tree costs almost nothing and it needs nothing installed.

**A `.toc` change needs a client restart**, not `/reload`: the client reads TOC files only at startup. Watch says so when it copies one. A brand-new addon folder is also only discovered at the character screen.

`make deploy` does one copy and exits.

## What gets copied

`tools/build` assembles `.build/<Name>/` first, and that is exactly what the game gets and what a release packages:

- the addon folder, without dotfiles and Markdown
- every `Libs/<Lib>/` its TOC references that exists in `libs/`, copied in (the shared library is embedded privately into each addon)
- an addon-local `Libs/` folder, if one exists, copied as is

Then every `.toc` is resolved with `tools/toc.lua` the way the client loads it (file lines in order, XML `Script` and `Include` expanded in place). A file that is missing, or differs in letter case, fails the build: Windows would forgive the case, a Mac player's client would not.

## Where it copies to

The Forever beta install by default:

```
/mnt/c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns
```

To point somewhere else (the launch folder once Blizzard names it, or Retail to compare), create `deploy.local` at the repo root; it is gitignored:

```
ADDONS_DIR="/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns"
```

`ADDONS_DIR=... make deploy` overrides it for one run.

## Safety rules

The copy deletes files in the target that the build no longer has, so it refuses anything that looks wrong:

- `ADDONS_DIR` must end in `Interface/AddOns`.
- A target that is a link is refused. Junctions show up as links in WSL. Remove one with `rm "<path>"`: no `-r` and no trailing slash, which unlinks it without touching what it points to. Never `rm -rf` a junction from WSL; that deletes the real files behind it.
- A non-empty target without the `.deployed-by-forever-addons` marker is refused: it may be an addon installed by CurseForge or by hand. Move it yourself if it should be replaced.

## History

Until 2026-09-22 HelloForever was a junction from `AddOns\HelloForever` into `C:\Users\matth\src\wow-addons\HelloForever`. That junction was removed (the Windows repo is untouched and no longer used) and replaced by this copy.
