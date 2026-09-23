-- End to end: package the fixture with the real packager (no upload), unzip it, and
-- load what a player would install through the WoW fake.
describe("tools/package", function()
  local Wow = require("support.wow")
  local out = ".release/PackFixture/out"
  local unzipped = ".release/PackFixture/unzipped"

  local function run(command)
    local ok = os.execute(command .. " >/dev/null 2>&1")
    return ok == 0 or ok == true
  end

  local function read(path)
    local f = assert(io.open(path))
    local text = f:read("*a")
    f:close()
    return text
  end

  setup(function()
    assert(run("ADDONS_ROOT=spec/fixtures tools/package PackFixture 0.1.0"), "tools/package failed")
    assert(run("rm -rf " .. unzipped .. " && mkdir -p " .. unzipped))
    assert(run("unzip -q -o " .. out .. "/PackFixture-0.1.0-forever.zip -d " .. unzipped))
  end)

  it("substitutes the version into the TOC", function()
    -- The packager writes CRLF line endings on purpose, for players on Windows.
    assert.matches("## Version: 0%.1%.0\r?\n", read(unzipped .. "/PackFixture/PackFixture.toc"))
  end)

  it("ships an addon that loads, with the library embedded and debug code dead", function()
    local wow = Wow.new()
    local ns = wow:loadAddon("PackFixture", { root = unzipped, libs = "/nonexistent" })
    assert.is_true(ns.shipped)
    assert.is_nil(ns.debugOnly)
    assert.is_table(ns.Kit.SavedData)
  end)

  it("includes the changelog, headed by the version", function()
    assert.matches("^## 0%.1%.0 %(", read(unzipped .. "/PackFixture/CHANGELOG.md"))
  end)

  it("refuses an addon without .pkgmeta, which is not published", function()
    assert.is_false(run("tools/package HelloForever 0.1.0"))
  end)

  it("refuses to upload without a CurseForge token and project id", function()
    assert.is_false(run("CF_API_KEY= ADDONS_ROOT=spec/fixtures tools/package PackFixture 0.1.0 --upload"))
    assert.is_false(run("CF_API_KEY=x ADDONS_ROOT=spec/fixtures tools/package PackFixture 0.1.0 --upload"))
  end)

  it("refuses a version that is not X.Y.Z[-beta.N]", function()
    assert.is_false(run("ADDONS_ROOT=spec/fixtures tools/package PackFixture v1"))
  end)
end)
