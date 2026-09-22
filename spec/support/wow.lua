-- A fake of the Forever client for specs, built from tools/wow/forever_api.lua so it
-- is strict where the client is strict:
--   - a global Forever does not define is an error to read, not a nil
--   - a frame has exactly the methods its widget type has on Forever
--   - RegisterEvent refuses events Forever does not know, with the client's message
--   - secret values error on arithmetic, length and indexing
-- and honest where it is not: a Forever global the fake has not implemented is an
-- error that says so, never a silent nil.
--
-- Known gaps: type() of a secret is "userdata" (the client reports the underlying type);
-- no taint, no combat lockdown enforcement, no real event order. The in-game
-- checklist in docs/process/production.md covers those.
--
--   local Wow = require("support.wow")
--   local wow = Wow.new({ level = 12 })
--   local ns = wow:loadAddon("HelloForever")   -- files in TOC order, then ADDON_LOADED
--   wow:fire("PLAYER_LOGIN")
--   wow:slash("/hf health")
--   assert.are.same({ ... }, wow.printed)

local api = dofile("tools/wow/forever_api.lua")
local toc = dofile("tools/toc.lua")

local Wow = {}
Wow.__index = Wow

local function set(list)
  local s = {}
  for _, v in ipairs(list) do
    s[v] = true
  end
  return s
end

-- Every top-level global name Forever defines, plus the variables .luacheckrc lists
-- as extras (verified in game).
local foreverGlobals = { WOW_PROJECT_ID = true, WOW_PROJECT_MAINLINE = true, SlashCmdList = true }
local foreverFields = {} -- "C_AddOns.GetAddOnMetadata" and friends
for _, key in ipairs({ "lua", "api", "framexml", "framexml_lod", "frames", "frames_lod", "tables" }) do
  for _, name in ipairs(api[key]) do
    foreverGlobals[name:match("^[^.]+")] = true
    foreverFields[name] = true
  end
end
local foreverEvents = set(api.events)

-- Template mixin methods, copied from Blizzard's source on the forever branch.
-- Add a template here, with its source file, before a spec may use it.
local templateMethods = {
  -- Gethe/wow-ui-source forever, Interface/AddOns/Blizzard_SharedXML/Backdrop.lua
  BackdropTemplate = set({
    "OnBackdropLoaded",
    "OnBackdropSizeChanged",
    "GetEdgeSize",
    "SetupTextureCoordinates",
    "SetupPieceVisuals",
    "SetBorderBlendMode",
    "HasBackdropInfo",
    "ClearBackdrop",
    "ApplyBackdrop",
    "SetBackdrop",
    "GetBackdrop",
    "GetBackdropColor",
    "SetBackdropColor",
    "GetBackdropBorderColor",
    "SetBackdropBorderColor",
  }),
}

-- All methods of a widget type, following inheritance.
local methodCache = {}
local function methodsOf(widgetType)
  if not methodCache[widgetType] then
    local methods, seen = {}, {}
    local function collect(name)
      if seen[name] then
        return
      end
      seen[name] = true
      local widget = api.widgets[name]
      for _, method in ipairs(widget.methods) do
        methods[method] = true
      end
      for _, parent in ipairs(widget.inherits) do
        collect(parent)
      end
    end
    collect(widgetType)
    methodCache[widgetType] = methods
  end
  return methodCache[widgetType]
end

local function isA(widgetType, wanted)
  if widgetType == wanted then
    return true
  end
  for _, parent in ipairs(api.widgets[widgetType].inherits) do
    if parent ~= widgetType and isA(parent, wanted) then
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------ secret values

local SECRET = {} -- metatable identity, hidden behind __metatable
local secretMeta = { __metatable = SECRET }
local function refuse(what)
  return function()
    error("attempt to " .. what .. " a secret value", 2)
  end
end
for _, op in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm" }) do
  secretMeta[op] = refuse("perform arithmetic on")
end
secretMeta.__lt = refuse("compare")
secretMeta.__le = refuse("compare")
secretMeta.__len = refuse("get length of")
secretMeta.__index = refuse("index")
secretMeta.__newindex = refuse("index")
secretMeta.__call = refuse("call")
secretMeta.__tostring = function()
  return "<secret>"
end
secretMeta.__concat = function(a, b)
  local function text(v)
    return getmetatable(v) == SECRET and "<secret>" or tostring(v)
  end
  return text(a) .. text(b)
end

local function issecretvalue(v)
  return type(v) == "userdata" and getmetatable(v) == SECRET
end

-- A userdata, not a table: Lua 5.1 consults __len only for userdata.
local function newSecret()
  local secret = newproxy(true)
  local meta = getmetatable(secret)
  for k, v in pairs(secretMeta) do
    meta[k] = v
  end
  return secret
end

-- ------------------------------------------------------------------ widgets

local noop = function() end
local behaviors = {}

function behaviors:GetObjectType()
  return self.__type
end
function behaviors:IsObjectType(wanted)
  return isA(self.__type, wanted)
end
function behaviors:GetName()
  return self.__name
end
function behaviors:GetParent()
  return self.__parent
end
function behaviors:Show()
  self.__shown = true
end
function behaviors:Hide()
  self.__shown = false
end
function behaviors:IsShown()
  return self.__shown
end
function behaviors:SetShown(shown)
  self.__shown = not not shown
end
function behaviors:SetScript(script, handler)
  self.__scripts[script] = handler
end
function behaviors:GetScript(script)
  return self.__scripts[script]
end
function behaviors:HookScript(script, handler)
  local previous = self.__scripts[script]
  self.__scripts[script] = previous and function(...)
    previous(...)
    handler(...)
  end or handler
end
function behaviors:RegisterEvent(event)
  if not foreverEvents[event] then
    error(('Frame:RegisterEvent(): Attempt to register unknown event "%s"'):format(tostring(event)), 2)
  end
  self.__events[event] = true
end
function behaviors:RegisterUnitEvent(event, ...)
  if not foreverEvents[event] then
    error(('Frame:RegisterUnitEvent(): Attempt to register unknown event "%s"'):format(tostring(event)), 2)
  end
  self.__events[event] = set({ ... })
end
function behaviors:UnregisterEvent(event)
  self.__events[event] = nil
end
function behaviors:UnregisterAllEvents()
  self.__events = {}
end
function behaviors:IsEventRegistered(event)
  return self.__events[event] ~= nil
end
function behaviors:SetPoint(point, relativeTo, relativePoint, x, y)
  if type(relativeTo) == "number" then -- SetPoint("TOP", x, y)
    relativeTo, relativePoint, x, y = nil, nil, relativeTo, relativePoint
  end
  self.__points[#self.__points + 1] = { point, relativeTo or self.__parent, relativePoint or point, x or 0, y or 0 }
end
function behaviors:GetPoint(index)
  local p = self.__points[index or 1]
  if p then
    return p[1], p[2], p[3], p[4], p[5]
  end
end
function behaviors:GetNumPoints()
  return #self.__points
end
function behaviors:ClearAllPoints()
  self.__points = {}
end
function behaviors:SetText(text)
  self.__text = text
end
function behaviors:GetText()
  return self.__text
end
function behaviors:SetValue(value)
  self.__value = value
end
function behaviors:GetValue()
  return self.__value
end
function behaviors:SetMinMaxValues(min, max)
  self.__min, self.__max = min, max
end
function behaviors:GetMinMaxValues()
  return self.__min, self.__max
end
function behaviors:CreateFontString(name)
  return self.__wow:_widget("FontString", name, self)
end
function behaviors:CreateTexture(name)
  return self.__wow:_widget("Texture", name, self)
end

function Wow:_widget(widgetType, name, parent, templates)
  if not api.widgets[widgetType] then
    error(('CreateFrame: unknown frame type "%s"'):format(tostring(widgetType)), 3)
  end
  local methods = methodsOf(widgetType)
  local extra = {}
  for template in (templates or ""):gmatch("[^,%s]+") do
    local mixin = templateMethods[template]
    if not mixin then
      error(('CreateFrame: template "%s" is not faked; add its methods to spec/support/wow.lua'):format(template), 3)
    end
    for method in pairs(mixin) do
      extra[method] = true
    end
  end
  local widget = setmetatable({
    __wow = self,
    __type = widgetType,
    __name = name,
    __parent = parent,
    __shown = true,
    __scripts = {},
    __events = {},
    __points = {},
  }, {
    __index = function(_, key)
      if methods[key] or extra[key] then
        return behaviors[key] or noop
      end
    end,
  })
  if name then
    rawset(self.env, name, widget) -- the client makes named frames global
  end
  self.frames[#self.frames + 1] = widget
  return widget
end

-- ------------------------------------------------------------------ the environment

local defaults = {
  name = "Tester",
  level = 10,
  health = 80,
  healthMax = 100,
  inCombat = false,
  locale = "enUS",
  interface = 16001,
}

function Wow.new(state)
  local wow = setmetatable({
    printed = {},
    errors = {},
    written = {},
    frames = {},
    addons = {},
    declared = {},
    state = {},
  }, Wow)
  for k, v in pairs(defaults) do
    wow.state[k] = v
  end
  for k, v in pairs(state or {}) do
    wow.state[k] = v
  end
  wow.env = wow:_env()
  return wow
end

function Wow:secret(value)
  local _ = value -- the fake does not need the value; a secret hides it anyway
  return newSecret()
end

function Wow:_env()
  local wow = self
  local env = {}
  wow.env = env -- widgets created below (UIParent) register named globals in it

  -- Only names Forever really defines may be provided; this keeps the fake honest.
  local function provide(name, value)
    assert(foreverGlobals[name], "the fake may not invent " .. name)
    rawset(env, name, value)
  end

  -- A C_* style namespace that errors on any field the fake has not implemented.
  local function namespace(prefix, fields)
    return setmetatable(fields, {
      __index = function(_, key)
        local full = prefix .. "." .. tostring(key)
        if foreverFields[full] then
          error(full .. " exists on Forever but is not faked; add it to spec/support/wow.lua", 2)
        end
        error(full .. " is not defined on Forever", 2)
      end,
    })
  end

  -- Lua: plain 5.1's own functions and libraries, plus WoW's aliases, each only if
  -- Forever has it.
  local aliases = {
    format = string.format,
    strlower = string.lower,
    strupper = string.upper,
    strlen = string.len,
    strsub = string.sub,
    strfind = string.find,
    strmatch = string.match,
    strrep = string.rep,
    strbyte = string.byte,
    strchar = string.char,
    strrev = string.reverse,
    gsub = string.gsub,
    gmatch = string.gmatch,
    floor = math.floor,
    ceil = math.ceil,
    abs = math.abs,
    max = math.max,
    min = math.min,
    sqrt = math.sqrt,
    tinsert = table.insert,
    tremove = table.remove,
    sort = table.sort,
    date = os.date,
    time = os.time,
    strtrim = function(s, chars)
      chars = chars and ("[" .. chars:gsub("[%]%%%^%-]", "%%%0") .. "]") or "%s"
      return (s:gsub("^" .. chars .. "+", ""):gsub(chars .. "+$", ""))
    end,
    strsplit = function(delimiter, s, pieces)
      local out, start = {}, 1
      while true do
        if pieces and #out == pieces - 1 then
          break
        end
        local i, j = s:find(delimiter, start, true)
        if not i then
          break
        end
        out[#out + 1] = s:sub(start, i - 1)
        start = j + 1
      end
      out[#out + 1] = s:sub(start)
      return unpack(out)
    end,
    strjoin = function(delimiter, ...)
      return table.concat({ ... }, delimiter)
    end,
    wipe = function(t)
      for k in pairs(t) do
        t[k] = nil
      end
      return t
    end,
  }
  for _, name in ipairs(api.lua) do
    local top = name:match("^[^.]+")
    if rawget(env, top) == nil then
      local value = aliases[top]
      if value == nil and name == top then
        value = _G[top]
      elseif value == nil and type(_G[top]) == "table" then
        value = {}
        for k, v in pairs(_G[top]) do
          value[k] = v
        end
      end
      if value ~= nil then
        rawset(env, top, value)
      end
    end
  end
  if rawget(env, "table") then
    rawget(env, "table").wipe = aliases.wipe
  end

  -- The WoW API the fake implements. Grow this as specs need more.
  provide("print", function(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[i] = tostring((select(i, ...)))
    end
    wow.printed[#wow.printed + 1] = table.concat(parts, " ")
  end)
  local errorHandler = function(err)
    wow.errors[#wow.errors + 1] = err
  end
  provide("geterrorhandler", function()
    return errorHandler
  end)
  provide("seterrorhandler", function(handler)
    errorHandler = handler
  end)
  provide("CreateFrame", function(widgetType, name, parent, templates)
    return wow:_widget(widgetType, name, parent or rawget(env, "UIParent"), templates)
  end)
  provide("UIParent", wow:_widget("Frame", "UIParent"))
  provide("issecretvalue", issecretvalue)
  provide("InCombatLockdown", function()
    return wow.state.inCombat
  end)
  provide("GetLocale", function()
    return wow.state.locale
  end)
  provide("GetTime", function()
    return wow.state.time or 0
  end)
  provide("UnitName", function(unit)
    return unit == "player" and wow.state.name or nil
  end)
  provide("UnitLevel", function(unit)
    return unit == "player" and wow.state.level or 0
  end)
  provide("UnitHealth", function(unit)
    return unit == "player" and wow.state.health or 0
  end)
  provide("UnitHealthMax", function(unit)
    return unit == "player" and wow.state.healthMax or 0
  end)
  provide("GetBuildInfo", function()
    local version, build = api.build:match("^(%d+%.%d+%.%d+)%.(%d+)$")
    return version, build, "", wow.state.interface
  end)
  provide("WOW_PROJECT_MAINLINE", 1)
  provide("WOW_PROJECT_ID", 1)
  provide("SlashCmdList", {})
  provide(
    "C_AddOns",
    namespace("C_AddOns", {
      GetAddOnMetadata = function(name, field)
        local addon = wow.addons[name]
        return addon and addon.metadata[field]
      end,
    })
  )

  return setmetatable(env, {
    __index = function(_, name)
      if wow.declared[name] then
        return nil
      end
      if foreverGlobals[name] then
        error(tostring(name) .. " exists on Forever but is not faked; add it to spec/support/wow.lua", 2)
      end
      error(tostring(name) .. " is not defined on Forever", 2)
    end,
    __newindex = function(_, name, value)
      wow.written[name] = true
      rawset(env, name, value)
    end,
  })
end

-- ------------------------------------------------------------------ driving it

-- Fire an event at every frame registered for it, in the order frames were created.
function Wow:fire(event, ...)
  local frames = {}
  for i, frame in ipairs(self.frames) do
    frames[i] = frame
  end
  for _, frame in ipairs(frames) do
    local registration = frame.__events[event]
    local unit = ...
    if registration == true or (type(registration) == "table" and registration[unit]) then
      local handler = frame.__scripts.OnEvent
      if handler then
        handler(frame, event, ...)
      end
    end
  end
end

-- Run a slash command as if typed into the chat box.
function Wow:slash(line)
  local command, rest = line:match("^(%S+)%s*(.-)$")
  command = command:lower()
  for name, value in pairs(self.env) do
    local key = type(name) == "string" and name:match("^SLASH_(.-)%d+$")
    if key and type(value) == "string" and value:lower() == command then
      return rawget(self.env, "SlashCmdList")[key](rest, nil)
    end
  end
  error("no slash command " .. command)
end

-- Run one file in the environment, as the client runs each file of an addon.
function Wow:loadFile(path, addonName, ns)
  local chunk = assert(loadfile(path))
  setfenv(chunk, self.env)
  chunk(addonName, ns)
  return ns
end

-- Load an addon the way the client does: its files in TOC order sharing one
-- namespace, then its saved variables, then ADDON_LOADED.
-- opts.root: folder holding addon folders (default "addons")
-- opts.libs: where Libs/<Lib>/ lives if the addon does not carry it (default "libs")
-- opts.saved: { GlobalName = value } for its SavedVariables
function Wow:loadAddon(name, opts)
  opts = opts or {}
  local root = (opts.root or "addons") .. "/" .. name
  local libs = opts.libs or "libs"
  local tocName = name .. ".toc"
  local file = assert(io.open(root .. "/" .. tocName))
  local metadata = toc.parse(file:read("*a")).metadata
  file:close()
  self.addons[name] = { metadata = metadata }
  for _, key in ipairs({ "SavedVariables", "SavedVariablesPerCharacter" }) do
    for global in (metadata[key] or ""):gmatch("[^,%s]+") do
      self.declared[global] = true
    end
  end

  local _, paths = toc.loadOrder(root, tocName, nil, function(path)
    local lib, rest = path:match("^Libs/([^/]+)/(.+)$")
    if lib and not toc.exists(root .. "/" .. path) then
      return libs .. "/" .. lib .. "/" .. rest
    end
    return root .. "/" .. path
  end)
  local ns = opts.ns or {}
  for _, path in ipairs(paths) do
    self:loadFile(path, name, ns)
  end
  for global, value in pairs(opts.saved or {}) do
    rawset(self.env, global, value) -- the client sets these, not the addon
  end
  self:fire("ADDON_LOADED", name)
  return ns
end

-- Load a pure Core file with only the Lua both WoW and plain Lua 5.1 have. Anything
-- else is an error, backing up the wow_core lint rule at runtime.
function Wow.loadCore(path, ns)
  ns = ns or {}
  local env = setmetatable({}, {
    __index = function(_, key)
      error("Core code may not use " .. tostring(key), 2)
    end,
    __newindex = function(_, key)
      error("Core code may not write the global " .. tostring(key), 2)
    end,
  })
  for _, name in ipairs(api.portable) do
    local top, field = name:match("^([^.]+)%.?(.*)$")
    if field == "" then
      rawset(env, top, _G[top])
    else
      local lib = rawget(env, top)
      if not lib then
        lib = setmetatable({}, {
          __index = function(_, key)
            error("Core code may not use " .. top .. "." .. tostring(key), 2)
          end,
        })
        rawset(env, top, lib)
      end
      rawset(lib, field, _G[top][field])
    end
  end
  local chunk = assert(loadfile(path))
  setfenv(chunk, env)
  chunk("Core", ns)
  return ns
end

return Wow
