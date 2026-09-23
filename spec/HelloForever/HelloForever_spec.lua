-- HelloForever through the WoW fake: proves the harness runs real addon glue, and
-- pins the sandbox's behaviour so a refactor cannot silently break an experiment.
describe("HelloForever", function()
  local Wow = require("support.wow")
  local wow

  local function load(saved)
    wow = Wow.new()
    wow:loadAddon("HelloForever", { saved = saved })
    wow:fire("PLAYER_LOGIN")
  end

  it("greets with login #1 on a fresh character", function()
    load()
    assert.matches("Login #1 on this character", wow.printed[1], 1, true)
  end)

  it("counts on from saved per-character data and keeps a saved false", function()
    load({ HelloForeverCharDB = { logins = 4, point = { "TOP", 1, 2 }, flag = false } })
    assert.matches("Login #5 on this character", wow.printed[1], 1, true)
    assert.is_false(wow.env.HelloForeverCharDB.flag)
  end)

  it("reports health out of combat", function()
    load()
    wow:slash("/hf health")
    assert.are.equal("HelloForever: health is 80 / 100", wow.printed[2])
  end)

  it("reports secret health in combat instead of computing with it", function()
    load()
    wow.state.health = wow:secret(40)
    wow:slash("/hf health")
    assert.matches("secret value right now", wow.printed[2], 1, true)
  end)

  it("forwards secret health to the bar, which accepts it", function()
    load()
    wow:slash("/hf") -- show the frame
    wow.state.health = wow:secret(40)
    wow:fire("UNIT_HEALTH", "player")
    assert.is_true(wow.env.issecretvalue(wow.env.HelloForeverFrame.health:GetValue()))
  end)

  it("says whether each saved table came off disk", function()
    load({ HelloForeverCharDB = { logins = 1 } })
    wow:slash("/hf db")
    assert.matches("account=no character=yes", wow.printed[2], 1, true)
  end)

  it("prints the client version from the TOC and build", function()
    load()
    wow:slash("/hf version")
    assert.matches("interface 16001", wow.printed[2], 1, true)
  end)

  it("writes no global beyond its saved variables and slash commands", function()
    load()
    local allowed = {
      HelloForeverDB = true,
      HelloForeverCharDB = true,
      SLASH_HELLOFOREVER1 = true,
      SLASH_HELLOFOREVER2 = true,
    }
    for name in pairs(wow.written) do
      assert.is_true(allowed[name], "unexpected global " .. name)
    end
  end)
end)
