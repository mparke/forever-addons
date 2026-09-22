# Testing

Three layers, from most code to least:

| Layer | What | How | Gate |
|---|---|---|---|
| Pure Core | Data models, rules, migrations, formatting: anything that can take its inputs as arguments | busted on real Lua 5.1, written test-first | per-file coverage floor, 90% |
| Glue | Event handlers, frames, slash commands | busted against a fake of the WoW API that rejects names Forever does not have | specs where the fake is honest |
| In game | Secret values, taint, real event order and payloads, saved data across a real restart | the probe addon and the checklist in [production.md](production.md) | run before a release, recorded in the PR |

## The TDD loop

1. Write the spec for the next behaviour in `spec/<Name>/...`. Run `make test`; watch it fail for the right reason.
2. Write the least code in `Core/` that passes.
3. Refactor with the spec green. `make check` before pushing.

Name specs `*_spec.lua`. One `describe` per module, one `it` per behaviour, phrased as the behaviour: `it("keeps a saved false instead of replacing it with the default")`.

## Coverage

`make coverage` runs the specs with luacov and fails if any file under `libs/` or any `Core/` folder is below 90% of lines (`COVERAGE_FLOOR` in the Makefile). A file in scope that no spec loads counts as 0%. Glue outside Core is not counted: coverage there would reward testing the fake.

## What the fake does not prove

A spec passing against the fake means the logic is right given the fake's assumptions. It says nothing about secret values (the fake returns plain numbers), taint, combat lockdown, the real order of events at login, or whether saved variables load on this beta build. Those are the in-game checklist's job.

The WoW API fake and the helper that loads an addon's files the way the client does arrive with the shared library; this doc gains their usage then.
