-- The probe's pure logic: resolving API paths and describing event arguments,
-- including secret ones, without touching the client.
describe("ForeverProbe Core", function()
  local Wow = require("support.wow")
  local Probe = Wow.loadCore("addons/ForeverProbe/Core/Probe.lua").Probe

  local SECRET = {}
  local function isSecret(v)
    return v == SECRET
  end

  describe("resolve", function()
    local env = { CreateFrame = print, C_AddOns = { GetAddOnMetadata = print }, Flag = false }

    it("finds a global and a namespaced function", function()
      assert.are.same({ print, true }, { Probe.resolve(env, "CreateFrame") })
      assert.are.same({ print, true }, { Probe.resolve(env, "C_AddOns.GetAddOnMetadata") })
    end)

    it("finds a value that is false", function()
      assert.are.same({ false, true }, { Probe.resolve(env, "Flag") })
    end)

    it("names the first missing part", function()
      assert.are.same({ nil, false, "C_Nope" }, { Probe.resolve(env, "C_Nope.Thing") })
      assert.are.same({ nil, false, "C_AddOns.Missing" }, { Probe.resolve(env, "C_AddOns.Missing") })
    end)

    it("stops at a value that is not a table", function()
      assert.are.same({ nil, false, "CreateFrame.x" }, { Probe.resolve(env, "CreateFrame.x") })
    end)

    it("refuses something that is not a dotted name", function()
      assert.has_error(function()
        Probe.resolve(env, "os.execute('x')")
      end, "not an API path: os.execute('x')")
    end)
  end)

  describe("describe", function()
    it("shows each kind of value briefly", function()
      assert.are.equal('"hi"', Probe.describe("hi", isSecret))
      assert.are.equal("42", Probe.describe(42, isSecret))
      assert.are.equal("false", Probe.describe(false, isSecret))
      assert.are.equal("nil", Probe.describe(nil, isSecret))
      assert.are.equal("function", Probe.describe(print, isSecret))
      assert.are.equal("table", Probe.describe({}, isSecret))
    end)

    it("marks a secret without touching it", function()
      assert.are.equal("<secret>", Probe.describe(SECRET, isSecret))
    end)

    it("shortens long strings", function()
      assert.are.equal('"' .. string.rep("a", 40) .. '..."', Probe.describe(string.rep("a", 100), isSecret))
    end)
  end)

  describe("describeArgs", function()
    it("lists every argument, keeping trailing nils", function()
      assert.are.equal('"player", <secret>, nil', Probe.describeArgs(isSecret, "player", SECRET, nil))
      assert.are.equal("", Probe.describeArgs(isSecret))
    end)
  end)

  describe("newLog", function()
    it("keeps the newest entries up to its capacity, oldest first", function()
      local log = Probe.newLog(2)
      log:add("a")
      log:add("b")
      log:add("c")
      assert.are.same({ "b", "c" }, log:entries())
    end)

    it("stays correct long past its capacity", function()
      local log = Probe.newLog(3)
      for i = 1, 1000 do
        log:add(i)
      end
      assert.are.same({ 998, 999, 1000 }, log:entries())
    end)
  end)

  describe("parseCommand", function()
    it("splits the command from its argument, lowercasing the command", function()
      assert.are.same({ "watch", "SCREENSHOT_SUCCEEDED" }, { Probe.parseCommand("  WATCH  SCREENSHOT_SUCCEEDED ") })
      assert.are.same({ "", "" }, { Probe.parseCommand("") })
    end)
  end)
end)
