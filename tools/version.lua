-- Version math for tools/release. Versions are X.Y.Z releases and X.Y.Z-beta.N betas,
-- independent per addon (tags <Addon>/vX.Y.Z).
--
-- As a module: local version = dofile("tools/version.lua")
-- As a command: lua tools/version.lua next <bump> [existing versions...]
--               lua tools/version.lua previous <version> [existing versions...]

local M = {}

function M.parse(text)
  local major, minor, patch, rest = tostring(text):match("^(%d+)%.(%d+)%.(%d+)(.*)$")
  if not major then
    return nil
  end
  for _, part in ipairs({ major, minor, patch }) do
    if #part > 1 and part:sub(1, 1) == "0" then
      return nil
    end
  end
  local beta
  if rest ~= "" then
    beta = rest:match("^%-beta%.([1-9]%d*)$")
    if not beta then
      return nil
    end
  end
  return { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch), beta = tonumber(beta) }
end

local function format(v)
  local text = string.format("%d.%d.%d", v.major, v.minor, v.patch)
  return v.beta and (text .. "-beta." .. v.beta) or text
end

-- Negative, zero or positive, like a comparator. A beta sorts before its release.
function M.compare(a, b)
  local x, y = assert(M.parse(a), a), assert(M.parse(b), b)
  for _, key in ipairs({ "major", "minor", "patch" }) do
    if x[key] ~= y[key] then
      return x[key] - y[key]
    end
  end
  if x.beta == y.beta then
    return 0
  end
  if not x.beta then
    return 1
  end
  if not y.beta then
    return -1
  end
  return x.beta - y.beta
end

local function latest(versions, wantBeta)
  local best
  for _, v in ipairs(versions) do
    local parsed = M.parse(v)
    if parsed and (wantBeta or not parsed.beta) and (not best or M.compare(v, best) > 0) then
      best = v
    end
  end
  return best
end

-- The version a changelog for `target` starts after: for a release, the latest earlier
-- release (stable players see everything since theirs); for a beta, the latest earlier
-- version of either kind. Nil when there is none.
function M.previous(existing, target)
  local isBeta = M.parse(target).beta ~= nil
  local best
  for _, v in ipairs(existing) do
    local parsed = M.parse(v)
    if parsed and M.compare(v, target) < 0 and (isBeta or not parsed.beta) then
      if not best or M.compare(v, best) > 0 then
        best = v
      end
    end
  end
  return best
end

-- The next version given the versions already tagged and a bump: major, minor, patch
-- (from the latest release), beta (continue the newest beta line past the latest
-- release, or start X.Y+1.0-beta.1), or an exact version newer than all of them.
function M.next(existing, bump)
  local newest = latest(existing, true)
  if M.parse(bump) then
    if newest and M.compare(bump, newest) <= 0 then
      error(string.format("version %s is not newer than %s", bump, newest), 0)
    end
    return bump
  end

  local release = M.parse(latest(existing, false) or "0.0.0")
  local target = { major = release.major, minor = release.minor, patch = release.patch }
  if bump == "major" then
    target = { major = release.major + 1, minor = 0, patch = 0 }
  elseif bump == "minor" then
    target = { major = release.major, minor = release.minor + 1, patch = 0 }
  elseif bump == "patch" then
    target.patch = release.patch + 1
  elseif bump == "beta" then
    local line = newest and M.parse(newest)
    if line and line.beta and M.compare(newest, format(release)) > 0 then
      line.beta = line.beta + 1
      return format(line)
    end
    target = { major = release.major, minor = release.minor + 1, patch = 0, beta = 1 }
  else
    error(
      string.format('bump must be major, minor, patch, beta or an exact X.Y.Z[-beta.N], got "%s"', tostring(bump)),
      0
    )
  end
  return format(target)
end

if arg and arg[0] and arg[0]:match("tools/version%.lua$") and arg[1] == "previous" then
  local existing = {}
  for i = 3, #arg do
    existing[#existing + 1] = arg[i]
  end
  print(M.previous(existing, arg[2]) or "")
elseif arg and arg[0] and arg[0]:match("tools/version%.lua$") and arg[1] == "next" then
  local existing = {}
  for i = 3, #arg do
    existing[#existing + 1] = arg[i]
  end
  local ok, result = pcall(M.next, existing, arg[2])
  if not ok then
    io.stderr:write(result, "\n")
    os.exit(1)
  end
  print(result)
end

return M
