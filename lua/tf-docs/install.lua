local config = require("tf-docs.config")
local registry = require("tf-docs.registry")
local logging = require("tf-docs.logging")

local M = {}

local function get_install_path(provider_name)
  local install_dir = config.options.provider_docs_install_location
  return vim.fn.expand(vim.fs.normalize(install_dir .. "/" .. provider_name))
end

local function get_installed_providers()
  local install_dir = vim.fn.expand(config.options.provider_docs_install_location)
  local installed = {}

  if vim.fn.isdirectory(install_dir) == 0 then
    return installed
  end

  for name, typ in vim.fs.dir(install_dir) do
    if typ == "directory" then
      table.insert(installed, name)
    end
  end

  return installed
end

local function to_true_map(t)
  local m = {}
  for _, v in ipairs(t) do
    m[v] = true
  end
  return m
end

--- Sequential Async Runner
--- @param cmds table List of commands
--- @param on_success function|nil Callback on total completion
--- @param on_fail function|nil Callback if any command in the chain fails
local function run_async_cmds(cmds, on_success, on_fail)
  local function run_next(index)
    if index > #cmds then
      if on_success then
        on_success()
      end
      return
    end

    vim.system(cmds[index], { text = true }, function(obj)
      if obj.code == 0 then
        run_next(index + 1)
      elseif on_fail then
        on_fail(obj.stderr or "Unknown error")
      end
    end)
  end

  run_next(1)
end

--- Clone full repo or sparse checkout
M.install_provider = function(provider_name)
  local adaptor = registry.get(provider_name)
  if not adaptor then
    return
  end

  local url = adaptor.repo_url
  local sparse_dirs = adaptor._docs_root
  local target_path = get_install_path(provider_name)

  if vim.fn.isdirectory(target_path) ~= 0 then
    logging.warn("provider already installed, skipping")
    return nil
  end

  logging.info("Installing " .. provider_name .. " docs in the background...")

  local cmds = {}
  if sparse_dirs then
    cmds = {
      -- Shallow, blobless, sparse clone directly to the target path
      { "git", "clone", "--depth", "1", "--filter=blob:none", "--sparse", url, target_path },
      -- Set the specific directories (this automatically updates the working tree)
      { "git", "-C", target_path, "sparse-checkout", "set", sparse_dirs },
    }
  else
    cmds = {
      -- Standard blobless shallow clone
      { "git", "clone", "--depth", "1", "--filter=blob:none", url, target_path },
    }
  end

  run_async_cmds(cmds, function()
    logging.info("Successfully installed " .. provider_name)
  end, function(err_msg)
    logging.err(string.format("Failed to install %s.\nError: %s", provider_name, err_msg))
  end)
end

--- Update the provider via git pull
M.update_provider = function(provider_name)
  local target_path = get_install_path(provider_name)

  if vim.fn.isdirectory(target_path) == 0 then
    return
  end

  local cmds = {
    { "git", "-C", target_path, "fetch", "origin", "--quiet" },
    { "git", "-C", target_path, "reset", "--hard", "origin/HEAD" },
    { "git", "-C", target_path, "clean", "-fd" },
  }

  run_async_cmds(cmds, nil, function(err_msg)
    logging.err(string.format("Failed to update %s.\nError: %s", provider_name, err_msg))
  end)
end

--- Remove provider directory
M.remove_provider = function(provider_name)
  local target_path = get_install_path(provider_name)

  if vim.fn.isdirectory(target_path) == 0 then
    return
  end

  local status = vim.fn.delete(target_path, "rf")
  if status == 0 then
    logging.info("Removed " .. provider_name .. " docs.")
  else
    logging.err("Failed to remove " .. target_path)
  end
end

--- Main entry point for syncing state
M.lazy_installer = function()
  local installed = get_installed_providers()
  local installed_map = to_true_map(installed)

  -- Derive a plain list of required provider *names*.
  -- `config.options.providers` supports a mixed list:
  -- - "aws" (built-in provider name)
  -- - { name = "azure", repo_url = "...", ... } (custom provider)
  local required_names = {}
  local required_map = {}

  for _, spec in ipairs(config.options.providers or {}) do
    local name

    if type(spec) == "string" then
      name = spec
    elseif type(spec) == "table" then
      name = spec.name
    end

    if type(name) == "string" and name ~= "" and not required_map[name] then
      required_map[name] = true
      table.insert(required_names, name)
    end
  end

  -- Install or Update required providers.
  for _, provider_name in ipairs(required_names) do
    if installed_map[provider_name] then
      M.update_provider(provider_name)
    else
      M.install_provider(provider_name)
    end
  end

  -- Remove providers no longer present in config.
  for _, provider_name in ipairs(installed) do
    if not required_map[provider_name] then
      M.remove_provider(provider_name)
    end
  end
end

return M
