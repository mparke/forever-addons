# ForeverKit

The shared library every addon here embeds. It is copied into each addon's `Libs/ForeverKit/` at build time and loads into that addon's private namespace as `ns.Kit`: no global, no LibStub, so each addon runs exactly the library version it was tested with ([DECISION-001](../../docs/decisions/DECISION-001-repo-foundations.md)).

Reference it from the addon's TOC before the addon's own files:

```
Libs\ForeverKit\ForeverKit.xml
```

| Module | Kind | What |
|---|---|---|
| `Core/SavedData.lua` | pure | Versioned saved tables with migrations run on a copy (production rule 1) |
| `Core/Locale.lua` | pure | enUS-based locale tables with per-locale translations (production rule 4) |
| `Events.lua` | glue | One frame per addon dispatching events to many handlers, errors isolated |

Each file's header comment documents its API. Specs: `spec/ForeverKit/`.
