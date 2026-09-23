-- Glue: one frame per addon dispatching to many handlers, run against the WoW fake.
describe("ForeverKit Events", function()
  local Wow = require("support.wow")
  local wow, events

  before_each(function()
    wow = Wow.new()
    local ns = wow:loadFile("libs/ForeverKit/Events.lua", "Test", {})
    events = ns.Kit.Events.new()
  end)

  local function registered(event)
    for _, frame in ipairs(wow.frames) do
      if frame:IsEventRegistered(event) then
        return true
      end
    end
    return false
  end

  it("registers an event with the client only when the first handler arrives", function()
    assert.is_false(registered("PLAYER_LOGIN"))
    events:On("PLAYER_LOGIN", function() end)
    assert.is_true(registered("PLAYER_LOGIN"))
  end)

  it("runs every handler in the order added, with the event and its arguments", function()
    local calls = {}
    events:On("UNIT_HEALTH", function(...)
      calls[#calls + 1] = { "first", ... }
    end)
    events:On("UNIT_HEALTH", function(...)
      calls[#calls + 1] = { "second", ... }
    end)
    wow:fire("UNIT_HEALTH", "player")
    assert.are.same({ { "first", "UNIT_HEALTH", "player" }, { "second", "UNIT_HEALTH", "player" } }, calls)
  end)

  it("unregisters the event when its last handler is removed", function()
    local a, b = function() end, function() end
    events:On("PLAYER_LOGIN", a)
    events:On("PLAYER_LOGIN", b)
    events:Off("PLAYER_LOGIN", a)
    assert.is_true(registered("PLAYER_LOGIN"))
    events:Off("PLAYER_LOGIN", b)
    assert.is_false(registered("PLAYER_LOGIN"))
  end)

  it("keeps running the other handlers when one raises, and reports the error", function()
    local ran = false
    events:On("PLAYER_LOGIN", function()
      error("handler broke")
    end)
    events:On("PLAYER_LOGIN", function()
      ran = true
    end)
    wow:fire("PLAYER_LOGIN")
    assert.is_true(ran)
    assert.are.equal(1, #wow.errors)
    assert.matches("handler broke", wow.errors[1])
  end)

  it("runs a Once handler a single time", function()
    local count = 0
    events:Once("PLAYER_ENTERING_WORLD", function()
      count = count + 1
    end)
    wow:fire("PLAYER_ENTERING_WORLD", true, false)
    wow:fire("PLAYER_ENTERING_WORLD", false, false)
    assert.are.equal(1, count)
    assert.is_false(registered("PLAYER_ENTERING_WORLD"))
  end)

  it("does not skip a handler when an earlier one removes itself mid-dispatch", function()
    local ran = {}
    local function first()
      ran[#ran + 1] = "first"
      events:Off("PLAYER_LOGIN", first)
    end
    events:On("PLAYER_LOGIN", first)
    events:On("PLAYER_LOGIN", function()
      ran[#ran + 1] = "second"
    end)
    wow:fire("PLAYER_LOGIN")
    assert.are.same({ "first", "second" }, ran)
  end)

  it("ignores removing a handler that was never added", function()
    events:Off("PLAYER_LOGIN", function() end)
    assert.is_false(registered("PLAYER_LOGIN"))
  end)

  it("fails loudly for an event Forever does not have", function()
    assert.has_error(function()
      events:On("NOT_AN_EVENT", function() end)
    end, 'Frame:RegisterEvent(): Attempt to register unknown event "NOT_AN_EVENT"')
  end)
end)
