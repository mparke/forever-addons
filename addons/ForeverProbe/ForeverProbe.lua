-- ForeverProbe: answer in-game questions fast. Dev-only, never published.
--   /probe watch EVENT     print each firing with its arguments; secret ones show <secret>
--   /probe unwatch EVENT
--   /probe log             replay what was captured this session (last 100)
--   /probe api PATH        does C_Foo.Bar exist on this client?
-- Captures live for the session only; watches are lost on /reload.

local _, ns = ...
local Kit, Probe = ns.Kit, ns.Probe

local PREFIX = "|cff88ccffProbe|r "
local events = Kit.Events.new()
local log = Probe.newLog(100)
local watching = {}

local function say(text)
  print(PREFIX .. text)
end

local function record(event, ...)
  local entry = ("%s %s(%s)"):format(date("%H:%M:%S"), event, Probe.describeArgs(issecretvalue, ...))
  log:add(entry)
  say(entry)
end

local function watch(event)
  if watching[event] then
    say("already watching " .. event)
    return
  end
  -- Registering an unknown event throws on the client; that answer is the point.
  local ok = pcall(events.On, events, event, record)
  if ok then
    watching[event] = true
    say("watching " .. event)
  else
    say(event .. " is not an event on this client")
  end
end

local function unwatch(event)
  if watching[event] then
    events:Off(event, record)
    watching[event] = nil
  end
  say("not watching " .. event)
end

local function showLog()
  local entries = log:entries()
  if #entries == 0 then
    say("no events captured yet; /probe watch EVENT first")
  end
  for _, entry in ipairs(entries) do
    say(entry)
  end
end

local function api(path)
  local ok, value, found, missing = pcall(Probe.resolve, _G, path)
  if not ok then
    say("not an API path: " .. path)
  elseif found then
    say(("%s = %s"):format(path, Probe.describe(value, issecretvalue)))
  else
    say(("%s is missing (no %s)"):format(path, missing))
  end
end

local function help()
  local names = {}
  for event in pairs(watching) do
    names[#names + 1] = event
  end
  table.sort(names)
  say("/probe watch EVENT | unwatch EVENT | log | api C_Foo.Bar")
  say("watching: " .. (#names > 0 and table.concat(names, ", ") or "nothing"))
end

SLASH_FOREVERPROBE1 = "/probe"
SlashCmdList.FOREVERPROBE = function(msg)
  local command, rest = Probe.parseCommand(msg)
  if command == "watch" and rest ~= "" then
    watch(rest:upper())
  elseif command == "unwatch" and rest ~= "" then
    unwatch(rest:upper())
  elseif command == "log" then
    showLog()
  elseif command == "api" and rest ~= "" then
    api(rest)
  else
    help()
  end
end
