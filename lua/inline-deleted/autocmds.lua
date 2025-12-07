-- autocmds.lua - Autocmd setup for inline-deleted.nvim
--- @class InlineDeletedAutocmds
local M = {}

--- Callback functions table
--- @class InlineDeletedCallbacks
--- @field should_activate fun(bufnr: number): boolean Check if buffer should have plugin active
--- @field refresh fun(bufnr: number) Refresh the display
--- @field refresh_debounced fun(bufnr: number) Debounced refresh
--- @field clear fun(bufnr: number) Clear extmarks
--- @field cleanup fun(bufnr: number) Cleanup state

--- Setup autocommands for automatic refresh
--- @param callbacks InlineDeletedCallbacks Table of callback functions
function M.setup(callbacks)
  -- Validate callbacks
  assert(type(callbacks) == "table", "callbacks must be a table")
  assert(type(callbacks.should_activate) == "function", "callbacks.should_activate must be a function")
  assert(type(callbacks.refresh) == "function", "callbacks.refresh must be a function")
  assert(type(callbacks.refresh_debounced) == "function", "callbacks.refresh_debounced must be a function")
  assert(type(callbacks.clear) == "function", "callbacks.clear must be a function")
  assert(type(callbacks.cleanup) == "function", "callbacks.cleanup must be a function")

  -- Create augroup
  local augroup = vim.api.nvim_create_augroup("InlineDeleted", { clear = true })

  -- Refresh on buffer changes
  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
    group = augroup,
    callback = function(args)
      if callbacks.should_activate(args.buf) then
        callbacks.refresh_debounced(args.buf)
      end
    end,
    desc = "Refresh inline deleted lines on buffer changes",
  })

  -- Refresh when entering a buffer
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function(args)
      if callbacks.should_activate(args.buf) then
        callbacks.refresh(args.buf)
      end
    end,
    desc = "Refresh inline deleted lines when entering buffer",
  })

  -- Clear when leaving buffer
  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    callback = function(args)
      callbacks.clear(args.buf)
    end,
    desc = "Clear inline deleted lines when leaving buffer",
  })

  -- Cleanup state on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(args)
      callbacks.cleanup(args.buf)
    end,
    desc = "Cleanup inline deleted state on buffer delete",
  })

  -- Refresh on gitsigns updates (if available)
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "GitSignsUpdate",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if callbacks.should_activate(bufnr) then
        callbacks.refresh_debounced(bufnr)
      end
    end,
    desc = "Refresh inline deleted lines on gitsigns update",
  })
end

return M
