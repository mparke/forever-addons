---@meta
-- Types for globals the client sets as variables, which Ketho's annotations do not
-- declare. Keep in step with extraReadGlobals / extraGlobals in .luacheckrc.

---Slash command handlers, keyed by the NAME in SLASH_NAME1 = "/cmd".
---@type table<string, fun(msg: string, editBox: table)>
SlashCmdList = {}

---The game project the client belongs to. Forever reports WOW_PROJECT_MAINLINE.
---@type integer
WOW_PROJECT_ID = 1

---@type integer
WOW_PROJECT_MAINLINE = 1
