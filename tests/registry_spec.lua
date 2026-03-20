require("plenary.busted")
local registry = require("tf-docs.registry")

local current = require("tests.providers.tfdocs_current")
local legacy = require("tests.providers.tfdocs_legacy")

local current_spec = vim.tbl_extend("force", { name = "tf-docs" }, current)
local legacy_spec = vim.tbl_extend("force", { name = "tf-docs-legacy" }, legacy)

describe("tf-docs provider registry integrity", function()
  before_each(function()
    registry.setup_adaptors({ current_spec, legacy_spec })
  end)

  -- Loop through every registered provider provider
  for _, provider in ipairs({ "tf-docs", "tf-docs-legacy" }) do
    it("validates the '" .. provider .. "' provider contract", function()
      local adaptor = registry.get(provider)

      -- 1. Ensure the module was actually loaded
      assert.is_table(adaptor, string.format("Provider '%s' failed to load or is not a table", provider))

      -- 2. Verify mandatory base fields (from the provider file)
      assert.is_string(adaptor.repo_url, provider .. " is missing repo_url")
      assert.is_string(adaptor.search_title, provider .. " is missing search_title")
      assert.is_string(adaptor.file_extension, provider .. " is missing file_extension")

      -- 3. Verify injected registry fields
      assert.is_string(adaptor._docs_root, provider .. " failed to receive _docs_root injection")
      assert.is_table(adaptor._docs_layout, provider .. " failed to receive _docs_layout injection")

      -- 4. Verify specific layout mapping (Resource and Data should always exist)
      assert.is_string(adaptor._docs_layout.resource, provider .. " layout is missing 'resource' mapping")
      assert.is_string(adaptor._docs_layout.data, provider .. " layout is missing 'data' mapping")
    end)
  end
end)
