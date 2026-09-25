-- The journal: whose it is, what has been seen, and what has happened. Entries are
-- only appended; the one change made to an entry afterwards is attaching its shot.

local _, ns = ...

local Journal = {}
ns.Journal = Journal

local function freshSeen()
  return { maps = {}, encounters = {} }
end

-- Claim the journal for the character logging in. Another character's journal (a
-- deleted character recreated with the same name and realm) moves to the end of
-- `archived` and a fresh one starts; nothing is ever deleted or overwritten.
---@param db TravelogueDB
---@param guid string UnitGUID("player"), checked not secret by the caller
---@return "new" | "same" | "archived"
function Journal.claim(db, guid)
  if type(guid) ~= "string" then
    error("Journal.claim: guid must be a string, got " .. type(guid), 2)
  end
  if db.guid == nil then
    db.guid = guid
    return "new"
  end
  if db.guid == guid then
    return "same"
  end
  db.archived[#db.archived + 1] = { guid = db.guid, entries = db.entries, seen = db.seen }
  db.guid, db.entries, db.seen = guid, {}, freshSeen()
  return "archived"
end

---@param db TravelogueDB
---@param entry TravelogueEntry
---@return number index
function Journal.add(db, entry)
  local index = #db.entries + 1
  db.entries[index] = entry
  return index
end

-- One capture can serve several entries; each gets its own copy of the shot.
---@param db TravelogueDB
---@param indexes number[]
---@param shot TravelogueShot
function Journal.attachShot(db, indexes, shot)
  for _, index in ipairs(indexes) do
    local entry = db.entries[index]
    if entry then
      local copy = {}
      for k, v in pairs(shot) do
        copy[k] = v
      end
      entry.shot = copy
    end
  end
end

local function first(set, id, caller)
  if type(id) ~= "number" then
    error(caller .. ": id must be a number, got " .. type(id), 3)
  end
  if set[id] then
    return false
  end
  set[id] = true
  return true
end

-- True the first time a map is asked about, and marks it seen.
---@param db TravelogueDB
---@param mapID number
---@return boolean
function Journal.firstMap(db, mapID)
  return first(db.seen.maps, mapID, "Journal.firstMap")
end

-- True the first time an encounter is asked about, and marks it seen.
---@param db TravelogueDB
---@param encounterID number
---@return boolean
function Journal.firstEncounter(db, encounterID)
  return first(db.seen.encounters, encounterID, "Journal.firstEncounter")
end

-- Up to n entries, newest first.
---@param db TravelogueDB
---@param n number
---@return TravelogueEntry[]
function Journal.latest(db, n)
  local list = {}
  for index = #db.entries, math.max(#db.entries - n + 1, 1), -1 do
    list[#list + 1] = db.entries[index]
  end
  return list
end
