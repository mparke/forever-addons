local name, ns = ...
ns.main = name
ns.sawLib = ns.fixLib == true
ns.dbAtLoad = NoLibDB
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, loaded)
  if loaded == name then
    ns.dbAtAddonLoaded = NoLibDB
  end
end)
