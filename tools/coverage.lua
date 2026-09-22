-- Enforce a per-file line-coverage floor on everything luacov is told to count
-- (.luacov: libs/ and every Core/ folder). A file in scope that no spec loads is
-- absent from luacov's report and counts as 0%, so untested modules cannot hide.
-- Usage: lua tools/coverage.lua <floor percent>

local floor = assert(tonumber(arg[1]), "usage: lua tools/coverage.lua <floor>")

local inScope = {}
local find =
  io.popen([[find libs addons -path '*/Core/*' -name '*.lua' 2>/dev/null; ]] .. [[find libs -name '*.lua' 2>/dev/null]])
for path in find:lines() do
  inScope[path] = true
end
find:close()

local reported = {}
local report = io.open("luacov.report.out")
if report then
  local inSummary = false
  for line in report:lines() do
    if line == "Summary" then
      inSummary = true
    elseif inSummary then
      local file, hits, missed = line:match("^(%S+)%s+(%d+)%s+(%d+)%s+[%d.]+%%$")
      if file then
        reported[file] = { hits = tonumber(hits), missed = tonumber(missed) }
      end
    end
  end
  report:close()
end

local files = {}
for path in pairs(inScope) do
  files[#files + 1] = path
end
table.sort(files)

if #files == 0 then
  print("coverage: no files in scope yet (libs/, */Core/)")
  return
end

local failed = false
for _, path in ipairs(files) do
  local r = reported[path]
  local pct, note = 0, "never loaded by any spec"
  if r then
    local total = r.hits + r.missed
    pct = total == 0 and 100 or 100 * r.hits / total
    note = string.format("%d/%d lines", r.hits, total)
  end
  local ok = pct >= floor
  failed = failed or not ok
  print(string.format("%s %6.2f%%  %s  (%s)", ok and "  " or "✗ ", pct, path, note))
end

if failed then
  io.stderr:write(string.format("coverage: below the %d%% floor; see luacov.report.out for missed lines\n", floor))
  os.exit(1)
end
print(string.format("coverage: every file at or above %d%%", floor))
