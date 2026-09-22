-- Production rule 1: a bad migration destroys a player's data for good, so every
-- path through SavedData.load is pinned here.
describe("ForeverKit SavedData", function()
  local Wow = require("support.wow")
  local SavedData = Wow.loadCore("libs/ForeverKit/Core/SavedData.lua").Kit.SavedData

  local function schema(overrides)
    local s = {
      version = 1,
      defaults = { count = 0, enabled = true, point = { "CENTER", 0, 0 }, options = { size = 10, color = "red" } },
      migrations = {},
    }
    for k, v in pairs(overrides or {}) do
      s[k] = v
    end
    return s
  end

  describe("with nothing saved", function()
    it("starts from a copy of the defaults stamped with the version", function()
      local db, status = SavedData.load(nil, schema({ version = 3, migrations = { [2] = print, [3] = print } }))
      assert.are.equal("new", status)
      assert.are.equal(3, db.schemaVersion)
      assert.are.equal(0, db.count)
    end)

    it("never shares a table with the defaults", function()
      local s = schema()
      local db = SavedData.load(nil, s)
      db.point[1] = "TOP"
      db.options.size = 99
      assert.are.equal("CENTER", s.defaults.point[1])
      assert.are.equal(10, s.defaults.options.size)
    end)
  end)

  it("resets a saved value that is not a table, and says what it was", function()
    local db, status, detail = SavedData.load("garbage", schema())
    assert.are.equal("reset", status)
    assert.are.equal(0, db.count)
    assert.matches("string", detail)
  end)

  describe("at the current version", function()
    it("returns the same table with missing keys filled in", function()
      local saved = { schemaVersion = 1, count = 7 }
      local db, status = SavedData.load(saved, schema())
      assert.are.equal("current", status)
      assert.are.equal(saved, db)
      assert.are.equal(7, db.count)
      assert.is_true(db.enabled)
    end)

    it("keeps a saved false instead of replacing it with the default", function()
      local db = SavedData.load({ schemaVersion = 1, enabled = false }, schema())
      assert.is_false(db.enabled)
    end)

    it("keeps keys it does not know, which a newer version may have written", function()
      local db = SavedData.load({ schemaVersion = 1, fromTheFuture = "x" }, schema())
      assert.are.equal("x", db.fromTheFuture)
    end)

    it("fills missing fields inside a saved record", function()
      local db = SavedData.load({ schemaVersion = 1, options = { size = 3 } }, schema())
      assert.are.same({ size = 3, color = "red" }, db.options)
    end)

    it("does not merge a saved list with the default list", function()
      local db = SavedData.load({ schemaVersion = 1, point = { "TOP" } }, schema())
      assert.are.same({ "TOP" }, db.point)
    end)

    it("treats data without a schemaVersion as version 1", function()
      local db, status = SavedData.load({ count = 2 }, schema())
      assert.are.equal("current", status)
      assert.are.equal(1, db.schemaVersion)
    end)
  end)

  describe("at an older version", function()
    it("applies each step in order and stamps each version", function()
      local order = {}
      local s = schema({
        version = 3,
        migrations = {
          [2] = function(db)
            order[#order + 1] = db.schemaVersion
            db.count = db.count * 10
          end,
          [3] = function(db)
            order[#order + 1] = db.schemaVersion
            db.count = db.count + 1
          end,
        },
      })
      local db, status, detail = SavedData.load({ schemaVersion = 1, count = 2 }, s)
      assert.are.equal("migrated", status)
      assert.are.equal("1 -> 3", detail)
      assert.are.same({ 1, 2 }, order)
      assert.are.equal(21, db.count)
      assert.are.equal(3, db.schemaVersion)
    end)

    it("uses a table a step returns as the new data", function()
      local s = schema({
        version = 2,
        migrations = {
          [2] = function(old)
            return { count = old.total }
          end,
        },
      })
      local db = SavedData.load({ schemaVersion = 1, total = 5 }, s)
      assert.are.equal(5, db.count)
      assert.are.equal(2, db.schemaVersion)
      assert.is_true(db.enabled)
    end)

    it("leaves the saved data untouched and unwritable when a step fails", function()
      local saved = { schemaVersion = 1, count = 2, nested = { a = 1 } }
      local s = schema({
        version = 2,
        migrations = {
          [2] = function(db)
            db.nested.a = 999
            error("step broke")
          end,
        },
      })
      local db, status, detail = SavedData.load(saved, s)
      assert.are.equal("failed", status)
      assert.are.equal(saved, db)
      assert.are.same({ schemaVersion = 1, count = 2, nested = { a = 1 } }, saved)
      assert.matches("step broke", detail)
      assert.is_false(SavedData.writable(status))
    end)
  end)

  it("leaves data from a newer addon version untouched and unwritable", function()
    local saved = { schemaVersion = 5, count = 1 }
    local db, status, detail = SavedData.load(saved, schema({ version = 2, migrations = { [2] = print } }))
    assert.are.equal("newer", status)
    assert.are.equal(saved, db)
    assert.is_nil(db.enabled)
    assert.are.equal("5 > 2", detail)
    assert.is_false(SavedData.writable(status))
  end)

  it("calls every other status writable", function()
    for _, status in ipairs({ "new", "reset", "current", "migrated" }) do
      assert.is_true(SavedData.writable(status), status)
    end
  end)

  it("refuses a schema that is missing a step, before touching any data", function()
    assert.has_error(function()
      SavedData.load({ schemaVersion = 1 }, schema({ version = 3, migrations = { [3] = print } }))
    end, "SavedData: schema version 3 has no migration step 2")
  end)
end)
