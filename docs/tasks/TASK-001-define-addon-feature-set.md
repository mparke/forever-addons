---
id: TASK-001
title: Define the addon feature set
type: task
status: backlog
priority: high
created: 2026-09-22
updated: 2026-09-22
depends_on: []
research:
  - research/forever-addon-field-guide.md
  - research/journey-addon-landscape.md
  - research/memento-deep-dive.md
---

# TASK-001: Define the addon feature set

## Goal

Decide what the first real addon is, feature by feature, before writing any code beyond HelloForever. The output is a written feature list split into MVP and later, with every MVP feature mapped to events and APIs already verified on Forever, plus the decisions the research left open.

## Context

- The landscape survey found no maintained addon that combines a per-character milestone timeline, the screenshot taken at each milestone, and notes. On Forever only Memento is alive, and it is a screenshot tool with no journal. That gap is the candidate.
- The Forever client is Mainline 12.1.5-plus with `camelot` as its game type, secret values in full, and no Mythic+, Housing, specialisations or Warbank. Forever-only surfaces are the Legacy system (achievements, `C_Traits` trees, currency 4225, reputation track 2802), `C_SwingTimer`, `C_AutoLoot`, `C_LootFrame`.
- The beta's SavedVariables loader bug means anything persisted is lost on client restart until Blizzard fixes it; per-character variables survive `/reload` within a session.

## Approach

1. List candidate milestones and for each name the event, its payload fields, whether the payload can be secret, and whether the subsystem loads on camelot (use the Memento deep dive's table as the template).
2. Decide the journal model: what a timeline entry holds (timestamp, zone, level, screenshot filename or index, note), how entries key (per character GUID), and the SavedVariables split.
3. Decide screenshot policy: which milestones capture, UI hidden or not, delay, and how an entry links to the file the client wrote (the client names files `WoWScrnShot_MMDDYY_HHMMSS`; the addon cannot read the filesystem, so it records its own timestamp at `SCREENSHOT_SUCCEEDED`).
4. Decide the Forever-specific features: Legacy Challenge completions, Legacy points, first-visit to a new zone, first kill of a dungeon boss, hardcore death if on that ruleset.
5. Decide what is explicitly out of scope for MVP: notes UI, export, sharing, RP integration.
6. Write the result as `docs/decisions/DECISION-001-feature-set.md` and a design doc skeleton.

## Acceptance criteria

- [ ] A feature list exists with MVP and later columns.
- [ ] Every MVP feature names its trigger event and the APIs it calls, each verified present on Forever build 69913 or newer.
- [ ] The SavedVariables strategy is decided, including how the beta bug is handled during development and what changes at launch.
- [ ] The addon has a working name and a one-sentence description.
- [ ] Open questions that need an in-game probe are listed with the exact `/etrace` or `/dump` command to run.

## Open questions to resolve in this task

- Does completing a Legacy Challenge fire `ACHIEVEMENT_EARNED`, and does Legacy point gain fire `CURRENCY_DISPLAY_UPDATE` for currency 4225?
- Is the Forever launch client still 16001, and does the launch folder name change? Affects nothing in the feature set but everything in the README.
- Does `SCREENSHOT_SUCCEEDED` fire for screenshots the player takes manually as well as `Screenshot()` calls, so the journal can attach player-initiated shots?

## Notes

Created 2026-09-22 after the HelloForever scaffold and the three research docs. Next step after this task: implement the MVP in a new addon folder beside HelloForever, junctioned the same way.
