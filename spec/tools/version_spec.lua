-- Version math for tools/release: independent semver per addon, betas as X.Y.Z-beta.N.
describe("tools/version.lua", function()
  local version = dofile("tools/version.lua")

  describe("parse", function()
    it("reads releases and betas", function()
      assert.are.same(
        { 1, 2, 3 },
        { version.parse("1.2.3").major, version.parse("1.2.3").minor, version.parse("1.2.3").patch }
      )
      assert.are.equal(2, version.parse("1.3.0-beta.2").beta)
      assert.is_nil(version.parse("1.2.3").beta)
    end)

    it("rejects anything else", function()
      for _, bad in ipairs({ "1.2", "v1.2.3", "1.2.3-alpha.1", "1.2.3-beta", "01.2.3", "" }) do
        assert.is_nil(version.parse(bad), bad)
      end
    end)
  end)

  describe("compare", function()
    it("orders by number, with a beta before its release", function()
      local sorted = { "1.10.0", "1.2.3", "1.3.0-beta.10", "1.3.0", "1.3.0-beta.2", "0.9.9" }
      table.sort(sorted, function(a, b)
        return version.compare(a, b) < 0
      end)
      assert.are.same({ "0.9.9", "1.2.3", "1.3.0-beta.2", "1.3.0-beta.10", "1.3.0", "1.10.0" }, sorted)
    end)
  end)

  describe("next", function()
    it("starts a first release from 0.0.0", function()
      assert.are.equal("0.1.0", version.next({}, "minor"))
      assert.are.equal("1.0.0", version.next({}, "major"))
      assert.are.equal("0.0.1", version.next({}, "patch"))
      assert.are.equal("0.1.0-beta.1", version.next({}, "beta"))
    end)

    it("bumps from the latest release", function()
      local existing = { "1.2.3", "1.0.0" }
      assert.are.equal("1.2.4", version.next(existing, "patch"))
      assert.are.equal("1.3.0", version.next(existing, "minor"))
      assert.are.equal("2.0.0", version.next(existing, "major"))
      assert.are.equal("1.3.0-beta.1", version.next(existing, "beta"))
    end)

    it("continues a beta line, and releases it with the matching bump", function()
      local existing = { "1.2.3", "1.3.0-beta.1", "1.3.0-beta.2" }
      assert.are.equal("1.3.0-beta.3", version.next(existing, "beta"))
      assert.are.equal("1.3.0", version.next(existing, "minor"))
      assert.are.equal("1.2.4", version.next(existing, "patch"))
    end)

    it("accepts an exact version newer than everything released", function()
      assert.are.equal("2.1.0", version.next({ "1.2.3" }, "2.1.0"))
    end)

    it("refuses an exact version that is not newer", function()
      assert.has_error(function()
        version.next({ "1.2.3" }, "1.2.3")
      end, "version 1.2.3 is not newer than 1.2.3")
    end)

    it("refuses an unknown bump", function()
      assert.has_error(function()
        version.next({}, "huge")
      end, 'bump must be major, minor, patch, beta or an exact X.Y.Z[-beta.N], got "huge"')
    end)
  end)
end)
