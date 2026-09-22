-- The fake is only useful if it is as strict as the client where it claims to be.
describe("support.wow", function()
  local Wow = require("support.wow")
  local wow

  before_each(function()
    wow = Wow.new()
  end)

  describe("frames", function()
    it("gives a frame the methods its widget type has on Forever", function()
      local bar = wow.env.CreateFrame("StatusBar")
      bar:SetMinMaxValues(0, 10)
      bar:SetValue(4)
      assert.are.equal(4, bar:GetValue())
      assert.are.equal("StatusBar", bar:GetObjectType())
    end)

    it("has no method a widget type lacks, like the client", function()
      local frame = wow.env.CreateFrame("Frame")
      assert.is_nil(frame.SetStatusBarTexture)
      assert.has_error(function()
        frame:SetStatusBarTexture("x")
      end)
    end)

    it("refuses a widget type Forever does not have", function()
      assert.has_error(function()
        wow.env.CreateFrame("NotAWidget")
      end, 'CreateFrame: unknown frame type "NotAWidget"')
    end)

    it("adds template methods only for templates it knows", function()
      local frame = wow.env.CreateFrame("Frame", nil, nil, "BackdropTemplate")
      frame:SetBackdrop({})
      assert.has_error(function()
        wow.env.CreateFrame("Frame", nil, nil, "SomeUnfakedTemplate")
      end, 'CreateFrame: template "SomeUnfakedTemplate" is not faked; add its methods to spec/support/wow.lua')
    end)

    it("makes a named frame a global, as the client does", function()
      local frame = wow.env.CreateFrame("Frame", "MyNamedFrame")
      assert.are.equal(frame, wow.env.MyNamedFrame)
      assert.are.equal("MyNamedFrame", frame:GetName())
    end)

    it("tracks shown state and points", function()
      local frame = wow.env.CreateFrame("Frame")
      frame:Hide()
      assert.is_false(frame:IsShown())
      frame:SetShown(true)
      assert.is_true(frame:IsShown())
      frame:SetPoint("CENTER", wow.env.UIParent, "CENTER", 10, 20)
      assert.are.same({ "CENTER", wow.env.UIParent, "CENTER", 10, 20 }, { frame:GetPoint() })
    end)
  end)

  describe("events", function()
    it("refuses an event Forever does not know, with the client's message", function()
      local frame = wow.env.CreateFrame("Frame")
      assert.has_error(function()
        frame:RegisterEvent("NOT_AN_EVENT")
      end, 'Frame:RegisterEvent(): Attempt to register unknown event "NOT_AN_EVENT"')
    end)

    it("delivers a fired event to each registered frame with its arguments", function()
      local seen = {}
      for i = 1, 2 do
        local frame = wow.env.CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:SetScript("OnEvent", function(self, event, ...)
          seen[#seen + 1] = { i, self == frame, event, ... }
        end)
      end
      wow:fire("PLAYER_LOGIN", "a", 1)
      assert.are.same({ { 1, true, "PLAYER_LOGIN", "a", 1 }, { 2, true, "PLAYER_LOGIN", "a", 1 } }, seen)
    end)

    it("stops delivering after UnregisterEvent", function()
      local count = 0
      local frame = wow.env.CreateFrame("Frame")
      frame:RegisterEvent("PLAYER_LOGIN")
      frame:SetScript("OnEvent", function()
        count = count + 1
      end)
      wow:fire("PLAYER_LOGIN")
      frame:UnregisterEvent("PLAYER_LOGIN")
      wow:fire("PLAYER_LOGIN")
      assert.are.equal(1, count)
    end)

    it("filters unit events to the registered units", function()
      local units = {}
      local frame = wow.env.CreateFrame("Frame")
      frame:RegisterUnitEvent("UNIT_HEALTH", "player")
      frame:SetScript("OnEvent", function(_, _, unit)
        units[#units + 1] = unit
      end)
      wow:fire("UNIT_HEALTH", "target")
      wow:fire("UNIT_HEALTH", "player")
      assert.are.same({ "player" }, units)
    end)
  end)

  describe("globals", function()
    it("fails a read of a global Forever does not define", function()
      assert.has_error(function()
        return wow.env.GetSpecialization
      end, "GetSpecialization is not defined on Forever")
    end)

    it("fails a read of a Forever global the fake does not implement yet, saying so", function()
      assert.has_error(function()
        return wow.env.GetGuildInfo
      end, "GetGuildInfo exists on Forever but is not faked; add it to spec/support/wow.lua")
    end)

    it("records every global the code writes", function()
      wow.env.SomeGlobal = 1
      assert.is_true(wow.written.SomeGlobal)
    end)

    it("runs securecallfunction's function, sending an error to the handler instead of raising", function()
      assert.are.equal(
        3,
        wow.env.securecallfunction(function(a, b)
          return a + b
        end, 1, 2)
      )
      wow.env.securecallfunction(function()
        error("inside")
      end)
      assert.are.equal(1, #wow.errors)
      assert.matches("inside", wow.errors[1])
    end)

    it("captures print output and errors sent to the error handler", function()
      wow.env.print("a", 1, nil)
      wow.env.geterrorhandler()("boom")
      assert.are.same({ "a 1 nil" }, wow.printed)
      assert.are.same({ "boom" }, wow.errors)
    end)
  end)

  describe("secret values", function()
    it("marks secrets for issecretvalue and nothing else", function()
      local secret = wow:secret(50)
      assert.is_true(wow.env.issecretvalue(secret))
      assert.is_false(wow.env.issecretvalue(50))
    end)

    it("errors on arithmetic, length and indexing, like the client", function()
      local secret = wow:secret(50)
      assert.has_error(function()
        return secret + 1
      end, "attempt to perform arithmetic on a secret value")
      assert.has_error(function()
        return #secret
      end, "attempt to get length of a secret value")
      assert.has_error(function()
        return secret.x
      end, "attempt to index a secret value")
    end)

    it("allows concatenation and tostring", function()
      local secret = wow:secret(50)
      assert.are.equal("hp <secret>", "hp " .. secret)
      assert.are.equal("<secret>", tostring(secret))
    end)

    it("returns the configured player values, secret or not", function()
      wow.state.health = wow:secret(40)
      assert.is_true(wow.env.issecretvalue(wow.env.UnitHealth("player")))
      assert.are.equal(100, wow.env.UnitHealthMax("player"))
    end)
  end)

  describe("slash commands", function()
    it("runs the handler whose SLASH_ global matches, with the rest of the line", function()
      local got
      wow.env.SLASH_THING1 = "/thing"
      wow.env.SlashCmdList.THING = function(msg)
        got = msg
      end
      wow:slash("/THING do it")
      assert.are.equal("do it", got)
    end)
  end)

  describe("loadAddon", function()
    it("runs the TOC's files in order with the name and one shared namespace", function()
      local ns = wow:loadAddon("TocFixture", { root = "spec/fixtures" })
      assert.are.same(
        { "Libs/Kit/Kit.lua", "Libs/Kit/Core/A.lua", "Libs/Kit/Core/B.lua", "Core.lua", "UI/Frame.lua" },
        ns.loaded
      )
    end)

    it("finds Libs/<Lib>/ in the libs folder when the addon does not carry it", function()
      local ns = wow:loadAddon("NoLibAddon", { root = "spec/fixtures", libs = "spec/fixtures/libs" })
      assert.is_true(ns.sawLib)
      assert.are.equal("NoLibAddon", ns.main)
    end)

    it("sets saved variables after the files run and before ADDON_LOADED, as the client does", function()
      local saved = { x = 1 }
      local ns = wow:loadAddon("NoLibAddon", {
        root = "spec/fixtures",
        libs = "spec/fixtures/libs",
        saved = { NoLibDB = saved },
      })
      assert.is_nil(ns.dbAtLoad)
      assert.are.equal(saved, ns.dbAtAddonLoaded)
    end)

    it("lets code read a declared saved variable that is not set as nil", function()
      local ns = wow:loadAddon("NoLibAddon", { root = "spec/fixtures", libs = "spec/fixtures/libs" })
      assert.is_nil(ns.dbAtAddonLoaded)
    end)

    it("answers GetAddOnMetadata from the TOC", function()
      wow:loadAddon("NoLibAddon", { root = "spec/fixtures", libs = "spec/fixtures/libs" })
      assert.are.equal("1.2.3", wow.env.C_AddOns.GetAddOnMetadata("NoLibAddon", "Version"))
    end)
  end)

  describe("loadCore", function()
    it("runs pure code with the Lua both WoW and plain Lua 5.1 have", function()
      local ns = Wow.loadCore("spec/fixtures/Core/Pure.lua")
      assert.are.equal(6, ns.double(3))
      assert.are.equal("3", ns.formatted)
    end)

    it("refuses any WoW API at runtime, backing up the lint rule", function()
      assert.has_error(function()
        Wow.loadCore("spec/fixtures/Core/Impure.lua")
      end, "Core code may not use CreateFrame")
    end)
  end)
end)
