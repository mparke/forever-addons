-- Resolve an addon's load order the way the client does: TOC file lines in order,
-- each XML file expanded in place through its <Script file> and <Include file>
-- tags, paths relative to the file that names them. Used by tools/build to verify
-- every listed file exists, and by the spec loader to load an addon in order.
--
-- As a module: local toc = dofile("tools/toc.lua")
-- As a command: lua tools/toc.lua <addon dir> <file.toc>  (prints the load order)
--               lua tools/toc.lua --libs <path/to/file.toc>  (prints referenced Libs/<Name>)

local M = {}

function M.exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function normalize(path)
  path = path:gsub("\\", "/"):gsub("/%./", "/"):gsub("^%./", "")
  return path
end

-- Parse TOC text into { metadata = { Key = "value" }, files = { "path", ... } }.
function M.parse(text)
  local parsed = { metadata = {}, files = {} }
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    line = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
    local key, value = line:match("^##%s*([^:]+):%s*(.-)$")
    if key then
      parsed.metadata[key:match("^(.-)%s*$")] = value
    elseif line ~= "" and not line:match("^#") then
      if line:find("[", 1, true) then
        error("TOC variables are not supported: " .. line, 0)
      end
      parsed.files[#parsed.files + 1] = normalize(line)
    end
  end
  return parsed
end

-- The Libs/<Name> folders a parsed TOC references, in first-seen order.
function M.libs(parsed)
  local seen, libs = {}, {}
  for _, file in ipairs(parsed.files) do
    local name = file:match("^Libs/([^/]+)/")
    if name and not seen[name] then
      seen[name] = true
      libs[#libs + 1] = name
    end
  end
  return libs
end

local function read(path)
  local f = assert(io.open(path, "r"))
  local text = f:read("*a")
  f:close()
  return text
end

local function dirname(path)
  return path:match("^(.*)/[^/]*$") or ""
end

-- The ordered list of Lua files the client would run for this TOC, relative to root,
-- and a second list with the filesystem path of each. Raises one error naming every
-- missing file. `exists` is injectable for tests; `resolve` maps a file to where it
-- actually lives (the spec loader uses it to find Libs/<Lib>/ in libs/ before a build).
function M.loadOrder(root, tocName, exists, resolve)
  exists = exists or M.exists
  resolve = resolve or function(file)
    return root .. "/" .. file
  end
  local order, paths, missing = {}, {}, {}

  local function visit(file)
    local path = resolve(file)
    if not exists(path) then
      missing[#missing + 1] = "missing: " .. file
      return
    end
    if file:match("%.xml$") then
      local xml = read(path):gsub("<!%-%-.-%-%->", "")
      local dir = dirname(file)
      for tag, ref in xml:gmatch('<%s*(%a+)%s+[^>]-file%s*=%s*"([^"]+)"') do
        if tag == "Script" or tag == "Include" then
          visit(normalize((dir ~= "" and dir .. "/" or "") .. ref))
        end
      end
    else
      order[#order + 1] = file
      paths[#paths + 1] = path
    end
  end

  for _, file in ipairs(M.parse(read(root .. "/" .. tocName)).files) do
    visit(file)
  end
  if #missing > 0 then
    error(tocName .. " lists files that do not exist:\n  " .. table.concat(missing, "\n  "), 0)
  end
  return order, paths
end

if arg and arg[0] and arg[0]:match("tools/toc%.lua$") then
  if arg[1] == "--libs" then
    for _, lib in ipairs(M.libs(M.parse(read(arg[2])))) do
      print(lib)
    end
    return M
  end
  local ok, result = pcall(M.loadOrder, arg[1], arg[2])
  if not ok then
    io.stderr:write(result, "\n")
    os.exit(1)
  end
  for _, file in ipairs(result) do
    print(file)
  end
end

return M
