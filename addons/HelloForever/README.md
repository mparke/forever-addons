# HelloForever

The sandbox: a first addon for **World of Warcraft: Forever** (Interface `16001`) and the place for in-game experiments. Never published. Its TOC also declares `120100, 120105`, so the same folder loads on Retail 12.1 for comparison.

It is exempt from the production rules (it never ships) but not from the checks: `make check` lints, type-checks and formats it like everything else.

## Try it

1. Launch the Forever beta. At the character screen open **AddOns** and tick *Hello Forever*. A brand-new folder is only discovered at login, not by `/reload`.
2. Log in. Chat greets you with this character's login count.
3. `/hf` toggles a movable frame with your name, level and a health bar. Drag it; the position survives `/reload`.
4. `/hf health` prints your health out of combat and explains why it cannot in combat (secret values). `/hf db` shows whether either SavedVariables table came off disk. `/hf version` prints the client. `/hf reset` re-centres the frame.

## What the beta will show you

- **SavedVariables do not load on a cold start** (build 1.60.1.69913, unacknowledged by Blizzard). `/hf db` after a `/reload` reports `character=yes`; after *Exit Game* and a relaunch it reports `no` for both, and the login counter is back to 1 even though the file under `WTF\Account\<acct>\SavedVariables` holds the right number. The only honest persistence test is Exit Game, relaunch, read before write. Back up that folder first: every failed load is followed by a save that overwrites the good file with defaults.
- **Health is secret in combat**, even solo in the open world. The bar keeps working because `StatusBar:SetValue` accepts secrets; `/hf health` reports the value is secret.

## Edit loop

Run `make watch` from the repo root, edit `HelloForever.lua`, type `/reload` in game. See [docs/process/local-loop.md](../../docs/process/local-loop.md).

## In-game tools

`/dump HelloForeverCharDB` inspects state, `/etrace` shows events, `/fstack` identifies frames, `/api C_Secrets` opens the in-game API docs. `ReloadUI()` from a timer or chat-driven code is blocked on every flavour (it needs a hardware event), so type `/reload`.
