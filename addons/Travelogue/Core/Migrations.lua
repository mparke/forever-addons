-- Travelogue's saved-data schema, handed to Kit.SavedData.load (production rule 1).
-- Every change to the shape below adds a step here, never an edit to a released one,
-- and a spec in spec/Travelogue/Core/Migrations_spec.lua with the old shape as fixture.

local _, ns = ...

---@class TravelogueShot
---@field file string? the predicted screenshot file name
---@field failed true? the client reported SCREENSHOT_FAILED
---@field lost true? the client never reported back

---@class TravelogueEntry
---@field at number time() when the entry was made
---@field kind string "start" | "level" | "achievement" | "boss" | "visit" | "death"
---@field level number? the character's level
---@field map number? uiMapID
---@field zone string?
---@field sub string?
---@field shot TravelogueShot?

---@class TravelogueSeen
---@field maps table<number, true>
---@field encounters table<number, true>

---@class TravelogueArchive
---@field guid string the earlier owner
---@field entries TravelogueEntry[]
---@field seen TravelogueSeen

---@class TravelogueDB
---@field schemaVersion number
---@field guid string? the character this journal belongs to
---@field settings { hideUI: boolean, shots: table<string, boolean> }
---@field seen TravelogueSeen
---@field entries TravelogueEntry[] oldest first, append only
---@field archived TravelogueArchive[] journals of earlier owners, oldest first

local Migrations = {}
ns.Migrations = Migrations

Migrations.schema = {
  version = 1,
  defaults = {
    settings = {
      hideUI = true,
      -- Deaths are off until the player turns them on (design review, 2026-09-25).
      shots = { level = true, achievement = true, boss = true, visit = true, death = false },
    },
    seen = { maps = {}, encounters = {} },
    entries = {},
    archived = {},
  },
  migrations = {},
}
