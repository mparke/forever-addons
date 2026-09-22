-- Production rule 4: every player-facing string goes through a locale table.
describe("ForeverKit Locale", function()
  local Wow = require("support.wow")
  local Locale = Wow.loadCore("libs/ForeverKit/Core/Locale.lua").Kit.Locale

  local enUS = {
    ["Screenshot saved"] = true,
    ["Reached level %d"] = true,
    greeting = "Hello, %s",
  }

  it("returns the enUS text, where true means the key is the text", function()
    local L = Locale.new("enUS", enUS)
    assert.are.equal("Screenshot saved", L["Screenshot saved"])
    assert.are.equal("Hello, %s", L.greeting)
  end)

  it("uses the client locale's translation", function()
    local L = Locale.new("deDE", enUS)
    Locale.add(L, "deDE", { ["Screenshot saved"] = "Screenshot gespeichert" })
    assert.are.equal("Screenshot gespeichert", L["Screenshot saved"])
  end)

  it("ignores translations for other locales", function()
    local L = Locale.new("enUS", enUS)
    Locale.add(L, "deDE", { ["Screenshot saved"] = "Screenshot gespeichert" })
    assert.are.equal("Screenshot saved", L["Screenshot saved"])
  end)

  it("falls back to enUS for a string the locale has not translated", function()
    local L = Locale.new("frFR", enUS)
    Locale.add(L, "frFR", {})
    assert.are.equal("Reached level %d", L["Reached level %d"])
    assert.are.equal("Reached level 5", L["Reached level %d"]:format(5))
  end)

  it("returns an unknown key as itself and lists it once as missing", function()
    local L = Locale.new("enUS", enUS)
    assert.are.equal("Not in the table", L["Not in the table"])
    local _ = L["Not in the table"]
    assert.are.same({ "Not in the table" }, Locale.missing(L))
  end)

  it("refuses true as a translation, which only enUS may use", function()
    local L = Locale.new("deDE", enUS)
    assert.has_error(function()
      Locale.add(L, "deDE", { greeting = true })
    end, 'Locale: deDE translation of "greeting" must be a string')
  end)
end)
