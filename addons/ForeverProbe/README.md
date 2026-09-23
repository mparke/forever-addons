# ForeverProbe

A dev-only addon for answering in-game questions quickly: does this API exist on this client, which events fire when I do something, with what arguments, and which of those arguments are secret. It has no `.pkgmeta`, so `tools/release` refuses it; it is never published. It is exempt from the production rules but not from the checks.

## Commands

| Command | Does |
|---|---|
| `/probe watch EVENT` | Print every firing of `EVENT` with its arguments; secret ones show as `<secret>`. An event this client does not know is reported, not thrown. |
| `/probe unwatch EVENT` | Stop watching it. |
| `/probe log` | Replay the last 100 captures of this session. |
| `/probe api PATH` | Whether `PATH` (`CreateFrame`, `C_Secrets.ShouldUnitHealthMaxBeSecret`) exists on this client, and what it is. |
| `/probe` | Help, and what is being watched. |

Watches and the log last for the session; `/reload` clears them. Event names are case-insensitive.

## What to run

The open in-game questions, each with its exact commands, live in the decision that raised them. Today that is [DECISION-002's open questions](../../docs/decisions/DECISION-002-feature-set.md#open-questions-for-the-probe), for Travelogue. Post the output, with the build number (`/dump GetBuildInfo()`), where the decision says.
