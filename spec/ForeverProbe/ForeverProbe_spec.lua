-- The probe's slash commands through the WoW fake.
describe("ForeverProbe", function()
  local Wow = require("support.wow")
  local wow

  before_each(function()
    wow = Wow.new()
    wow:loadAddon("ForeverProbe")
    wow:fire("PLAYER_LOGIN")
    wow.printed = {}
  end)

  local function last()
    return wow.printed[#wow.printed]
  end

  it("reports an event the client does not know instead of throwing", function()
    wow:slash("/probe watch NOT_AN_EVENT")
    assert.matches("NOT_AN_EVENT is not an event on this client", last(), 1, true)
    assert.are.same({}, wow.errors)
  end)

  it("captures a watched event with its arguments, secret ones marked", function()
    wow:slash("/probe watch UNIT_HEALTH")
    wow:fire("UNIT_HEALTH", "player", wow:secret(5))
    assert.matches('UNIT_HEALTH("player", <secret>)', last(), 1, true)
  end)

  it("upper-cases the event name it is given", function()
    wow:slash("/probe watch screenshot_succeeded")
    wow:fire("SCREENSHOT_SUCCEEDED")
    assert.matches("SCREENSHOT_SUCCEEDED()", last(), 1, true)
  end)

  it("stops capturing after unwatch", function()
    wow:slash("/probe watch PLAYER_LEVEL_UP")
    wow:slash("/probe unwatch PLAYER_LEVEL_UP")
    wow.printed = {}
    wow:fire("PLAYER_LEVEL_UP", 11)
    assert.are.same({}, wow.printed)
  end)

  it("replays the captured events with /probe log", function()
    wow:slash("/probe watch PLAYER_LEVEL_UP")
    wow:fire("PLAYER_LEVEL_UP", 11)
    wow:fire("PLAYER_LEVEL_UP", 12)
    wow.printed = {}
    wow:slash("/probe log")
    assert.are.equal(2, #wow.printed)
    assert.matches("PLAYER_LEVEL_UP(12)", wow.printed[2], 1, true)
  end)

  it("says when the log is empty", function()
    wow:slash("/probe log")
    assert.matches("no events captured", last(), 1, true)
  end)

  it("tells whether an API exists, and names what is missing", function()
    wow:slash("/probe api CreateFrame")
    assert.matches("CreateFrame = function", last(), 1, true)
    wow:slash("/probe api C_AddOns.NotAThing")
    assert.matches("C_AddOns.NotAThing is missing", last(), 1, true)
  end)

  it("reports a malformed API path instead of raising", function()
    wow:slash("/probe api os.execute('x')")
    assert.matches("not an API path", last(), 1, true)
  end)

  it("lists what it is watching", function()
    wow:slash("/probe watch PLAYER_LEVEL_UP")
    wow:slash("/probe watch SCREENSHOT_SUCCEEDED")
    wow:slash("/probe")
    assert.matches("watching: PLAYER_LEVEL_UP, SCREENSHOT_SUCCEEDED", table.concat(wow.printed, "\n"), 1, true)
  end)

  it("writes no global but its slash command", function()
    for name in pairs(wow.written) do
      assert.are.equal("SLASH_FOREVERPROBE1", name)
    end
  end)
end)
