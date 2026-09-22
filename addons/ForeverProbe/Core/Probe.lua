-- ForeverProbe's pure logic: resolve API paths, describe values without computing on
-- secrets, keep a bounded log, parse slash commands. The glue passes in _G and
-- issecretvalue, so this runs the same in busted as in the client.

local _, ns = ...

local Probe = {}
ns.Probe = Probe

-- Walk a dotted path ("C_AddOns.GetAddOnMetadata") from root. Returns value, true when
-- every part exists (a false value counts), else nil, false, and the path up to the
-- first missing part.
function Probe.resolve(root, path)
  if not path:match("^[%a_][%w_]*$") and not path:match("^[%a_][%w_]*%.[%w_.]*[%w_]$") then
    error("not an API path: " .. path, 2)
  end
  local value, walked = root, nil
  for part in path:gmatch("[^.]+") do
    walked = walked and (walked .. "." .. part) or part
    if type(value) ~= "table" then
      return nil, false, walked
    end
    value = value[part]
    if value == nil then
      return nil, false, walked
    end
  end
  return value, true
end

-- A short description of any value. A secret is only ever tested with isSecret, never
-- compared, measured or indexed.
function Probe.describe(value, isSecret)
  if isSecret(value) then
    return "<secret>"
  end
  local kind = type(value)
  if kind == "string" then
    if #value > 40 then
      return '"' .. value:sub(1, 40) .. '..."'
    end
    return '"' .. value .. '"'
  elseif kind == "number" or kind == "boolean" or kind == "nil" then
    return tostring(value)
  end
  return kind
end

function Probe.describeArgs(isSecret, ...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[i] = Probe.describe((select(i, ...)), isSecret)
  end
  return table.concat(parts, ", ")
end

-- A log that keeps the newest `capacity` entries. Explicit indexes, never #: the
-- length of a table with holes at the front is undefined.
function Probe.newLog(capacity)
  local items, first, last = {}, 1, 0
  local log = {}
  function log:add(entry)
    last = last + 1
    items[last] = entry
    if last - first + 1 > capacity then
      items[first] = nil
      first = first + 1
    end
  end
  function log:entries()
    local out = {}
    for i = first, last do
      out[#out + 1] = items[i]
    end
    return out
  end
  return log
end

-- "  WATCH  SCREENSHOT_SUCCEEDED " -> "watch", "SCREENSHOT_SUCCEEDED"
function Probe.parseCommand(msg)
  local command, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  return command:lower(), rest
end
