local M = {}

--- @class tf-docs.WindowConfig
--- @field split? "right"|"left"|"above"|"below" The direction to split the current window.
--- @field float? vim.api.keyset.win_config Standard Neovim floating window options.

--- @class tf-docs.Options
--- @field providers (string|tf-docs.ProviderAdaptor)[] List of providers to use. Accepts built-in names (e.g. "aws") or custom adaptor tables.
--- @field provider_docs_install_location? string (default: "~/.local/share/tf-docs")
--- @field win_config tf-docs.WindowConfig Window configuration for doc viewer
--- @field picker string|function builtin pickers ("snacks", "fzf", "telescope") or a custom function

--- @type tf-docs.Options
local defaults = {
  providers = {},
  picker = "snacks",
  provider_docs_install_location = vim.fn.stdpath("data") .. "/tf-docs",
  win_config = {
    split = "right",
    float = nil,
  },
}

--- @type tf-docs.Options
M.options = vim.deepcopy(defaults)

--- @param opts tf-docs.Options|nil
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  local install_dir = vim.fn.expand(M.options.provider_docs_install_location)
  if vim.fn.isdirectory(install_dir) == 0 then
    vim.fn.mkdir(install_dir, "p")
  end

  local registry = require("tf-docs.registry")
  registry.setup_adaptors(M.options.providers)

  local install = require("tf-docs.install")
  vim.schedule(function()
    install.lazy_installer()
  end)
end

return M
