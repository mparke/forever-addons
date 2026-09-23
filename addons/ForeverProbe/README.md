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

## Recipes for TASK-001 (#1)

Run these on the current beta build and post the output, with the build number (`/dump GetBuildInfo()`), to #1.

**Does completing a Legacy Challenge fire `ACHIEVEMENT_EARNED`?**

```
/probe watch ACHIEVEMENT_EARNED
/probe watch CRITERIA_EARNED
```

Complete a Legacy Challenge, then `/probe log`. `ACHIEVEMENT_EARNED`'s first argument is the achievement id.

**Does gaining Legacy points fire `CURRENCY_DISPLAY_UPDATE` for currency 4225?**

```
/probe watch CURRENCY_DISPLAY_UPDATE
```

Earn Legacy points. The first argument is the currency id; look for `4225`, and note the quantity and change arguments.

**Does `SCREENSHOT_SUCCEEDED` fire for screenshots the player takes?**

```
/probe watch SCREENSHOT_STARTED
/probe watch SCREENSHOT_SUCCEEDED
/probe watch SCREENSHOT_FAILED
```

Press Print Screen, then `/run Screenshot()`, then `/probe log`. Compare the two.
