-- The generated Forever API is what lint and the test fakes trust, so pin the facts
-- the research established. If a new beta build changes one of these, this fails and
-- the change gets a deliberate look instead of silently loosening the lint.
describe("tools/wow/forever_api.lua", function()
  local api = dofile("tools/wow/forever_api.lua")

  local function set(list)
    local s = {}
    for _, v in ipairs(list) do
      s[v] = true
    end
    return s
  end

  it("names the build and commit it came from", function()
    assert.matches("^%d+%.%d+%.%d+%.%d+$", api.build)
    assert.matches("^%x+$", api.commit)
    assert.are.equal(40, #api.commit)
  end)

  it("lists each group sorted and without duplicates", function()
    for _, key in ipairs({ "lua", "portable", "api", "framexml", "framexml_lod", "frames", "tables", "events" }) do
      local list = api[key]
      for i = 2, #list do
        assert(list[i - 1] < list[i], key .. " not strictly sorted at " .. list[i])
      end
    end
  end)

  it("has the APIs the addons rely on", function()
    local global = set(api.api)
    for _, name in ipairs({ "CreateFrame", "C_AddOns.GetAddOnMetadata", "issecretvalue", "InCombatLockdown" }) do
      assert.is_true(global[name], name)
    end
  end)

  it("lacks the specialization globals Forever does not load", function()
    -- Blizzard_DeprecatedSpecialization is gated to classic and standard, not camelot.
    local global = set(api.api)
    assert.is_nil(global.GetSpecialization)
    assert.is_nil(global.GetSpecializationInfo)
  end)

  it("knows the lifecycle and milestone events", function()
    local events = set(api.events)
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SCREENSHOT_SUCCEEDED", "ACHIEVEMENT_EARNED" }) do
      assert.is_true(events[event], event)
    end
  end)

  it("keeps portable a subset of WoW's Lua that plain Lua 5.1 also has", function()
    local wowLua = set(api.lua)
    for _, name in ipairs(api.portable) do
      assert.is_true(wowLua[name], name)
    end
    local portable = set(api.portable)
    assert.is_true(portable["string.format"])
    assert.is_nil(portable.strsplit) -- a WoW extension, absent from plain Lua
  end)

  it("describes widget inheritance down to Frame", function()
    local frame = api.widgets.Frame
    assert.is_table(frame)
    assert.is_true(set(frame.methods).RegisterEvent)
  end)
end)
