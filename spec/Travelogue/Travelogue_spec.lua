-- The whole addon through the WoW fake: the TOC's files load in order and share one
-- namespace. Events, the capture runner and the slash command arrive with the glue.
describe("Travelogue", function()
  local Wow = require("support.wow")
  local wow, ns

  before_each(function()
    wow = Wow.new()
    ns = wow:loadAddon("Travelogue")
  end)

  it("loads without errors and writes no globals", function()
    assert.are.same({}, wow.errors)
    assert.is_nil(next(wow.written))
  end)

  it("puts ForeverKit, the locale table and Core in its namespace", function()
    assert.is_table(ns.Kit.SavedData)
    assert.is_table(ns.L)
    assert.are.equal(1, ns.Migrations.schema.version)
    assert.is_function(ns.Journal.claim)
  end)

  it("saves one table per character", function()
    assert.are.equal("TravelogueCharDB", wow.addons.Travelogue.metadata.SavedVariablesPerCharacter)
    assert.is_nil(wow.addons.Travelogue.metadata.SavedVariables)
  end)
end)
