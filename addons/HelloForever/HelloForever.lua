-- HelloForever: a first addon for World of Warcraft: Forever (Interface 16001).
--
-- What this file teaches, in order:
--   1. the private addon namespace every file in the addon shares
--   2. SavedVariables: declared in the TOC, readable only after ADDON_LOADED
--   3. the lifecycle events an addon actually needs (ADDON_LOADED, PLAYER_LOGIN)
--   4. a slash command with sub-commands
--   5. a movable frame that remembers where you dragged it
--   6. secret values: combat data you may DISPLAY but must never COMPUTE with
--
-- Forever beta note (build 1.60.1.69913, 2026-09-22): SavedVariables under
-- WTF\Account\ are written on exit but never read back on a cold start. Per-character
-- variables ARE restored across /reload within one client run; account-wide ones are
-- not even that. So the state this addon cares about lives in HelloForeverCharDB, and
-- HelloForeverDB is kept only as a probe you can watch. Both come back on a fixed client.

local ADDON_NAME, ns = ... -- WoW passes the folder name and a fresh table to every file

---@class HelloForeverCharData
---@field logins integer how many times this character logged in with the addon on
---@field point [string, number, number] anchor point, x, y of the dragged frame

---@type HelloForeverCharData
local DEFAULTS = {
  logins = 0, -- how many times this character logged in with the addon on
  point = { "CENTER", 0, 200 }, -- where the frame was last dragged to
}

-- Merge defaults into the saved table without overwriting what the player already has.
-- Compare with `== nil`, never `not db[key]`: a saved `false` must survive.
local function initDatabase()
  -- Read BEFORE writing: whatever is non-nil here came off disk.
  ns.loadedFromDisk = {
    account = HelloForeverDB ~= nil,
    character = HelloForeverCharDB ~= nil,
  }
  HelloForeverDB = HelloForeverDB or { logins = 0 }
  HelloForeverCharDB = HelloForeverCharDB or {}
  for key, value in pairs(DEFAULTS) do
    if HelloForeverCharDB[key] == nil then
      HelloForeverCharDB[key] = value
    end
  end
  ns.db = HelloForeverCharDB
end

-- ---------------------------------------------------------------- the frame

local function createFrame()
  -- SetBackdrop left plain frames in 9.0.1; a backdrop needs BackdropTemplate.
  local frame = CreateFrame("Frame", "HelloForeverFrame", UIParent, "BackdropTemplate")
  frame:SetSize(220, 60)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
  })

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    ns.db.point = { point, x, y }
  end)

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.text:SetPoint("TOP", 0, -12)

  -- StatusBar:SetValue is one of the widget methods Blizzard marks AllowedWhenTainted,
  -- so the bar can show your health in combat even though Lua may not read the number.
  frame.health = CreateFrame("StatusBar", nil, frame)
  frame.health:SetPoint("BOTTOMLEFT", 12, 12)
  frame.health:SetPoint("BOTTOMRIGHT", -12, 12)
  frame.health:SetHeight(12)
  frame.health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  frame.health:SetStatusBarColor(0.2, 0.8, 0.2)

  frame:Hide()
  return frame
end

local function refresh()
  local frame = ns.frame
  frame.text:SetText(("%s, level %d"):format(UnitName("player"), UnitLevel("player")))
  frame.health:SetMinMaxValues(0, UnitHealthMax("player")) -- player's own max is never secret
  frame.health:SetValue(UnitHealth("player")) -- may be secret in combat; forwarding is fine
end

local function restorePosition()
  local point, x, y = unpack(ns.db.point)
  ns.frame:ClearAllPoints()
  ns.frame:SetPoint(point, UIParent, point, x, y)
end

-- ---------------------------------------------------------------- lifecycle

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterUnitEvent("UNIT_HEALTH", "player")

events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    -- ADDON_LOADED fires for EVERY addon; only ours has our SavedVariables ready.
    initDatabase()
    ns.frame = createFrame()
    restorePosition()
    events:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    -- Once per session (login and /reload), never on zoning.
    ns.db.logins = ns.db.logins + 1
    HelloForeverDB.logins = HelloForeverDB.logins + 1
    print(
      ("|cff33ff99HelloForever|r: hello, %s. Login #%d on this character. Type /hf for help."):format(
        UnitName("player"),
        ns.db.logins
      )
    )
  elseif event == "UNIT_HEALTH" and ns.frame:IsShown() then
    refresh()
  end
end)

-- ---------------------------------------------------------------- slash command

local function describeHealth()
  local health = UnitHealth("player")
  -- issecretvalue is the 12.x way to ask "may my code compute with this?".
  -- Out of combat it is a plain number; in combat it is secret and `health > 0` would error.
  if issecretvalue(health) then
    return "health is a secret value right now (in combat); the bar still shows it"
  end
  return ("health is %d / %d"):format(health, UnitHealthMax("player"))
end

local function describeDatabase()
  local yesno = function(flag)
    return flag and "yes" or "no"
  end
  print(
    ("HelloForever: loaded from disk at ADDON_LOADED: account=%s character=%s"):format(
      yesno(ns.loadedFromDisk.account),
      yesno(ns.loadedFromDisk.character)
    )
  )
  print(
    ("HelloForever: logins account=%d character=%d, frame at %s %d,%d"):format(
      HelloForeverDB.logins,
      ns.db.logins,
      ns.db.point[1],
      ns.db.point[2],
      ns.db.point[3]
    )
  )
end

SLASH_HELLOFOREVER1 = "/hf"
SLASH_HELLOFOREVER2 = "/helloforever"
SlashCmdList.HELLOFOREVER = function(msg)
  local command = (msg or ""):lower():match("^%s*(%S*)")
  if command == "show" or command == "" then
    ns.frame:SetShown(not ns.frame:IsShown())
    if ns.frame:IsShown() then
      refresh()
    end
  elseif command == "health" then
    print("HelloForever: " .. describeHealth())
  elseif command == "db" then
    describeDatabase()
  elseif command == "reset" then
    ns.db.point = { unpack(DEFAULTS.point) }
    restorePosition()
    print("HelloForever: position reset")
  elseif command == "version" then
    local version, build, _, interface = GetBuildInfo()
    print(
      ("HelloForever %s on client %s (build %s, interface %d), project %s"):format(
        C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"),
        version,
        build,
        interface,
        tostring(WOW_PROJECT_ID)
      )
    )
  else
    print("HelloForever: /hf [show|health|db|reset|version]")
  end
end
