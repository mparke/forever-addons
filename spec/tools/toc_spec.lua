describe("tools/toc.lua", function()
  local toc = dofile("tools/toc.lua")
  local fixture = "spec/fixtures/TocFixture"

  describe("parse", function()
    it("separates metadata from file lines and skips comments and blanks", function()
      local parsed = toc.parse("## Interface: 16001\n## Title: X\n# comment\n\nA.lua\n")
      assert.are.same({ Interface = "16001", Title = "X" }, parsed.metadata)
      assert.are.same({ "A.lua" }, parsed.files)
    end)

    it("normalizes backslashes and trims whitespace", function()
      assert.are.same({ "UI/Frame.lua" }, toc.parse("  UI\\Frame.lua  \r\n").files)
    end)

    it("rejects TOC variables it cannot resolve", function()
      assert.has_error(function()
        toc.parse("Foo_[Family].lua\n")
      end, "TOC variables are not supported: Foo_[Family].lua")
    end)
  end)

  describe("loadOrder", function()
    it("expands XML includes in place, relative to each XML file", function()
      assert.are.same({
        "Libs/Kit/Kit.lua",
        "Libs/Kit/Core/A.lua",
        "Libs/Kit/Core/B.lua",
        "Core.lua",
        "UI/Frame.lua",
      }, toc.loadOrder(fixture, "TocFixture.toc"))
    end)

    it("names every missing file, TOC or XML, in one error", function()
      local ok, err = pcall(toc.loadOrder, "spec/fixtures", "TocFixture/TocFixture.toc")
      assert.is_false(ok)
      assert.matches("missing: Libs/Kit/Kit.xml", err, 1, true)
      assert.matches("missing: Core.lua", err, 1, true)
    end)

    it("treats a wrong-case path as missing, as a case-sensitive filesystem would", function()
      local ok, err = pcall(toc.loadOrder, fixture, "TocFixture.toc", function(path)
        return path ~= fixture .. "/Core.lua" and toc.exists(path)
      end)
      assert.is_false(ok)
      assert.matches("missing: Core.lua", err, 1, true)
    end)
  end)

  describe("loadOrder with a resolver", function()
    it("reads and checks each file where the resolver says it lives, and returns those paths", function()
      local function resolve(file)
        return (file:gsub("^Libs/Kit/", "Libs/Kit/", 1))
      end
      local order, paths = toc.loadOrder(fixture, "TocFixture.toc", nil, function(file)
        return fixture .. "/" .. resolve(file)
      end)
      assert.are.equal("Core.lua", order[4])
      assert.are.equal(fixture .. "/Core.lua", paths[4])
      assert.are.equal(fixture .. "/Libs/Kit/Core/A.lua", paths[2])
    end)

    it("reports a file missing at its resolved location", function()
      local ok, err = pcall(toc.loadOrder, fixture, "TocFixture.toc", nil, function(file)
        return file == "Core.lua" and "nowhere/Core.lua" or fixture .. "/" .. file
      end)
      assert.is_false(ok)
      assert.matches("missing: Core.lua", err, 1, true)
    end)
  end)

  describe("libs", function()
    it("lists the Libs/<Name> folders a TOC references", function()
      assert.are.same({ "Kit" }, toc.libs(toc.parse("Libs\\Kit\\Kit.xml\nLibs/Kit/Other.lua\nCore.lua\n")))
    end)
  end)
end)
