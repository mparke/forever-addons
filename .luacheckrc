-- luacheck configuration. Globals come from Forever's real API, generated into
-- tools/wow/forever_api.lua from the pinned beta build, so a name the Forever client
-- does not define fails lint even if Retail has it. Two standards:
--
--   wow_core  Lua that WoW and plain Lua 5.1 share. Pure logic (any Core/ folder)
--             gets only this: no WoW API, so it runs identically in game and in busted.
--   wow       Everything the Forever client defines. Event and frame code gets this.
--
-- Run from the repo root (make lint does); the paths below are relative to it.

local api = assert(loadfile("tools/wow/forever_api.lua"))()

-- Turn dotted names ("C_AddOns.GetAddOnMetadata") into luacheck's nested field
-- definitions, so C_AddOns.Missing is flagged as an undefined field (W143).
local function define(target, names, opts)
  for _, name in ipairs(names) do
    local node = target
    local parts = {}
    for part in name:gmatch("[^.]+") do
      parts[#parts + 1] = part
    end
    for i, part in ipairs(parts) do
      node[part] = node[part] or {}
      if opts and opts.open then
        node[part].other_fields = true
      end
      if i < #parts then
        node[part].fields = node[part].fields or {}
        node = node[part].fields
      end
    end
  end
  return target
end

-- Globals the client sets as variables rather than functions, which the generated
-- lists do not carry. Each is verified on the build named in forever_api.lua, in game
-- or in Blizzard's own forever-branch UI code:
--   WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, SlashCmdList: HelloForever in game, 69913
--   _G: Blizzard_ChatFrameBase/Shared/SlashCommands.lua reads _G[...] (Gethe forever)
local extraReadGlobals = { "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "_G" }
local extraGlobals = { "SlashCmdList" } -- addons write their handlers into it

local wowRead = {}
define(wowRead, api.lua)
define(wowRead, api.api)
define(wowRead, api.framexml)
define(wowRead, api.framexml_lod)
define(wowRead, extraReadGlobals)
-- Frames and data tables have methods and members the lists do not enumerate.
define(wowRead, api.frames, { open = true })
define(wowRead, api.frames_lod, { open = true })
define(wowRead, api.tables, { open = true })

stds.wow_core = { read_globals = define({}, api.portable) }
stds.wow = { read_globals = wowRead, globals = define({}, extraGlobals, { open = true }) }

std = "wow"
max_line_length = 120
codes = true
-- Generated data and language-server declaration files are not code to lint.
exclude_files = { ".tools/**", ".build/**", ".release/**", "tools/wow/forever_api.lua", "tools/wow/annotations/**" }
ignore = {
  "212/self", -- unused self in methods is normal
}

-- Pure logic: no WoW API at all.
files["addons/*/Core/**/*.lua"] = { std = "wow_core" }
files["libs/*/Core/**/*.lua"] = { std = "wow_core" }

-- Tests and tools run under plain Lua 5.1 on Linux, never in the client.
files["spec/**/*.lua"] = { std = "lua51+busted" }
-- Fixtures are addon code the specs load into the WoW fake.
files["spec/fixtures/**/*.lua"] = { std = "wow", globals = { "NoLibDB" } }
files["tools/**/*.lua"] = { std = "lua51" }

-- Each addon declares the globals it owns: SavedVariables and slash command names.
files["addons/HelloForever/**/*.lua"] = {
  globals = { "HelloForeverDB", "HelloForeverCharDB", "SLASH_HELLOFOREVER1", "SLASH_HELLOFOREVER2" },
}
