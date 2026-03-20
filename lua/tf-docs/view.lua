local M = {}

local config = require("tf-docs.config")

-- create the buffer
function M.buf(path)
  path = vim.fn.expand(path)
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].bufhidden = "wipe"

  return buf
end

-- handle creating the buffer and opening the window
function M.open(path)
  local opts = config.options.win_config
  local buf = M.buf(path)
  if not buf then
    return
  end

  local win

  if opts.float then
    win = vim.api.nvim_open_win(buf, true, opts.float)
  elseif opts.split then
    win = vim.api.nvim_open_win(buf, true, {
      split = opts.split, -- "right", "left", "above", or "below"
      win = 0,
    })
  end

  if not win then
    return
  end

  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.cursorline = false
  wo.wrap = true

  return win
end

return M
