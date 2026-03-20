local M = {}

---@class tf-docs.ProviderAdaptor
---@field name string? set for custom providers
---@field repo_url string provider remote repo url
---@field search_title string telescope title
---@field file_extension string provider docs extension .md, .makdown .html.markdown
---@field is_legacy_docs  boolean? does the provider use 1.legacy = "website/docs/" with "r" and "d" or 2. current structure "docs/" with "resource" and "data"
---@field _docs_layout table? internally populated
---@field _docs_root string? internally populated
---@field _emoji_map table? internally populated

-- expose custom picker functions for users
M.open = require("tf-docs.view").open
M.get_doc_table = require("tf-docs.docs").get_doc_table

---@param opts tf-docs.Options
M.setup = function(opts)
  local config = require("tf-docs.config")
  config.setup(opts)
end

return M
