-- Travelogue's journal: whose it is, what has been seen, and the append-only list of
-- entries with the screenshot attached afterwards.
describe("Travelogue Journal", function()
  local Wow = require("support.wow")
  local Journal = Wow.loadCore("addons/Travelogue/Core/Journal.lua").Journal

  local function empty()
    return { seen = { maps = {}, encounters = {} }, entries = {}, archived = {} }
  end

  describe("claim", function()
    it("takes an unclaimed journal for the character", function()
      local db = empty()
      assert.are.equal("new", Journal.claim(db, "Player-1-A"))
      assert.are.equal("Player-1-A", db.guid)
    end)

    it("keeps what an unclaimed journal already holds", function()
      local db = empty()
      db.entries[1] = { at = 1, kind = "death" }
      Journal.claim(db, "Player-1-A")
      assert.are.same({ { at = 1, kind = "death" } }, db.entries)
    end)

    it("changes nothing when the character already owns it", function()
      local db = empty()
      Journal.claim(db, "Player-1-A")
      Journal.add(db, { at = 1, kind = "death" })
      assert.are.equal("same", Journal.claim(db, "Player-1-A"))
      assert.are.equal(1, #db.entries)
      assert.are.same({}, db.archived)
    end)

    it("archives another character's journal and starts a fresh one", function()
      local db = empty()
      Journal.claim(db, "Player-1-OLD")
      Journal.add(db, { at = 1, kind = "level", level = 2 })
      Journal.firstMap(db, 1429)
      Journal.firstEncounter(db, 1084)

      assert.are.equal("archived", Journal.claim(db, "Player-1-NEW"))
      assert.are.equal("Player-1-NEW", db.guid)
      assert.are.same({}, db.entries)
      assert.are.same({ maps = {}, encounters = {} }, db.seen)
      assert.are.same({
        {
          guid = "Player-1-OLD",
          entries = { { at = 1, kind = "level", level = 2 } },
          seen = { maps = { [1429] = true }, encounters = { [1084] = true } },
        },
      }, db.archived)
    end)

    it("never overwrites an archive, even for a GUID archived before", function()
      local db = empty()
      Journal.claim(db, "Player-1-A")
      Journal.add(db, { at = 1, kind = "death" })
      Journal.claim(db, "Player-1-B")
      Journal.claim(db, "Player-1-A")
      Journal.add(db, { at = 2, kind = "death" })
      Journal.claim(db, "Player-1-B")

      assert.are.equal(3, #db.archived)
      assert.are.same({ "Player-1-A", "Player-1-B", "Player-1-A" }, {
        db.archived[1].guid,
        db.archived[2].guid,
        db.archived[3].guid,
      })
      assert.are.same({ { at = 1, kind = "death" } }, db.archived[1].entries)
      assert.are.same({ { at = 2, kind = "death" } }, db.archived[3].entries)
    end)

    it("refuses a GUID that is not a string", function()
      assert.has_error(function()
        Journal.claim(empty(), nil)
      end, "Journal.claim: guid must be a string, got nil")
    end)
  end)

  describe("add", function()
    it("appends entries oldest first and returns each one's index", function()
      local db = empty()
      assert.are.equal(1, Journal.add(db, { at = 10, kind = "start" }))
      assert.are.equal(2, Journal.add(db, { at = 20, kind = "level", level = 2 }))
      assert.are.same({ "start", "level" }, { db.entries[1].kind, db.entries[2].kind })
    end)
  end)

  describe("attachShot", function()
    it("gives every entry of one capture the same file, each in its own table", function()
      local db = empty()
      Journal.add(db, { at = 1, kind = "level", level = 10 })
      Journal.add(db, { at = 1, kind = "achievement", id = 6 })
      Journal.attachShot(db, { 1, 2 }, { file = "WoWScrnShot_110426_165322.jpg" })

      assert.are.same({ file = "WoWScrnShot_110426_165322.jpg" }, db.entries[1].shot)
      assert.are.same({ file = "WoWScrnShot_110426_165322.jpg" }, db.entries[2].shot)
      assert.are_not.equal(db.entries[1].shot, db.entries[2].shot)
    end)

    it("records a failed or lost capture the same way", function()
      local db = empty()
      Journal.add(db, { at = 1, kind = "death" })
      Journal.attachShot(db, { 1 }, { failed = true })
      assert.are.same({ failed = true }, db.entries[1].shot)
    end)

    it("skips an index with no entry", function()
      local db = empty()
      Journal.add(db, { at = 1, kind = "death" })
      Journal.attachShot(db, { 1, 5 }, { lost = true })
      assert.are.same({ lost = true }, db.entries[1].shot)
      assert.are.equal(1, #db.entries)
    end)
  end)

  describe("firsts", function()
    it("says a map is new once, and remembers it", function()
      local db = empty()
      assert.is_true(Journal.firstMap(db, 1429))
      assert.is_false(Journal.firstMap(db, 1429))
      assert.is_true(Journal.firstMap(db, 1436))
      assert.are.same({ [1429] = true, [1436] = true }, db.seen.maps)
    end)

    it("says an encounter is new once, apart from maps", function()
      local db = empty()
      assert.is_true(Journal.firstEncounter(db, 1429))
      assert.is_false(Journal.firstEncounter(db, 1429))
      assert.is_true(Journal.firstMap(db, 1429))
    end)

    it("refuses a missing id", function()
      assert.has_error(function()
        Journal.firstMap(empty(), nil)
      end, "Journal.firstMap: id must be a number, got nil")
      assert.has_error(function()
        Journal.firstEncounter(empty(), "1084")
      end, "Journal.firstEncounter: id must be a number, got string")
    end)
  end)

  describe("latest", function()
    local db = empty()
    for i = 1, 12 do
      Journal.add(db, { at = i, kind = "level", level = i + 1 })
    end

    it("returns up to n entries, newest first", function()
      local list = Journal.latest(db, 3)
      assert.are.same({ 12, 11, 10 }, { list[1].at, list[2].at, list[3].at })
      assert.are.equal(3, #list)
    end)

    it("returns them all when there are fewer than n", function()
      assert.are.equal(12, #Journal.latest(db, 50))
      assert.are.equal(1, Journal.latest(db, 50)[12].at)
    end)

    it("returns nothing for an empty journal or n of 0", function()
      assert.are.same({}, Journal.latest(empty(), 10))
      assert.are.same({}, Journal.latest(db, 0))
    end)
  end)
end)
