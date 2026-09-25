-- Travelogue's saved-data schema as ForeverKit's SavedData loads it: version 1, its
-- defaults, and what each kind of saved file becomes.
describe("Travelogue Migrations", function()
  local Wow = require("support.wow")
  local SavedData = Wow.loadCore("libs/ForeverKit/Core/SavedData.lua").Kit.SavedData
  local schema = Wow.loadCore("addons/Travelogue/Core/Migrations.lua").Migrations.schema

  it("is at version 1 with no steps", function()
    assert.are.equal(1, schema.version)
    assert.are.same({}, schema.migrations)
  end)

  it("starts a first journal empty, with every screenshot kind on except deaths", function()
    local db, status = SavedData.load(nil, schema)
    assert.are.equal("new", status)
    assert.are.same({
      schemaVersion = 1,
      settings = {
        hideUI = true,
        shots = { level = true, achievement = true, boss = true, visit = true, death = false },
      },
      seen = { maps = {}, encounters = {} },
      entries = {},
      archived = {},
    }, db)
  end)

  it("gives each new journal its own tables", function()
    local a = SavedData.load(nil, schema)
    local b = SavedData.load(nil, schema)
    a.entries[1] = { kind = "death" }
    a.seen.maps[1429] = true
    assert.are.same({}, b.entries)
    assert.are.same({}, b.seen.maps)
  end)

  it("reads a file without schemaVersion as version 1 and keeps its entries", function()
    local saved = { guid = "Player-1-A", entries = { { at = 1, kind = "death" } } }
    local db, status = SavedData.load(saved, schema)
    assert.are.equal("current", status)
    assert.are.equal(1, db.schemaVersion)
    assert.are.same({ { at = 1, kind = "death" } }, db.entries)
    assert.are.same({ maps = {}, encounters = {} }, db.seen)
  end)

  it("keeps a player's choices and fills in a screenshot kind the file lacks", function()
    local saved = { schemaVersion = 1, settings = { hideUI = false, shots = { death = true, level = false } } }
    local db = SavedData.load(saved, schema)
    assert.are.same({
      hideUI = false,
      shots = { level = false, achievement = true, boss = true, visit = true, death = true },
    }, db.settings)
  end)

  it("keeps keys it does not know", function()
    local db = SavedData.load({ schemaVersion = 1, window = { x = 10 } }, schema)
    assert.are.same({ x = 10 }, db.window)
  end)

  it("leaves a file from a newer Travelogue untouched and not writable", function()
    local saved = { schemaVersion = 2, entries = { { at = 1, kind = "level", level = 2 } } }
    local db, status = SavedData.load(saved, schema)
    assert.are.equal("newer", status)
    assert.are.equal(saved, db)
    assert.is_false(SavedData.writable(status))
  end)
end)
