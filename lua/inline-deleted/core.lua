-- core.lua - Core logic for inline-deleted.nvim
local hunks = require("inline-deleted.hunks")
local render = require("inline-deleted.render")
local state = require("inline-deleted.state")
local config = require("inline-deleted.config")

local M = {}

---Check if plugin should be active for current buffer
---@param bufnr number? Buffer number (defaults to current buffer)
---@return boolean active Whether the plugin should be active for this buffer
function M.should_activate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check if buffer is valid
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if not state.get_enabled() then
    return false
  end

  -- Check filetype exclusions
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  for _, excluded in ipairs(config.get().exclude_filetypes) do
    if ft == excluded then
      return false
    end
  end

  -- Check if it's a git buffer
  return hunks.is_git_buffer(bufnr)
end

---Refresh deleted line display for a buffer
---@param bufnr number? Buffer number (defaults to current buffer)
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear existing extmarks
  render.clear(bufnr)

  -- Check if we should activate for this buffer
  if not M.should_activate(bufnr) then
    return
  end

  -- Get deleted hunks from gitsigns
  local deleted_hunks = hunks.get_deleted_hunks(bufnr)

  -- Render the hunks
  render.render_hunks(bufnr, deleted_hunks, config.get())
end

---Debounced refresh to avoid excessive updates
---@param bufnr number? Buffer number (defaults to current buffer)
function M.refresh_debounced(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Cancel existing timer
  state.clear_timer(bufnr)

  -- Start new timer
  local timer = vim.fn.timer_start(config.get().debounce_ms, function()
    M.refresh(bufnr)
    state.set_timer(bufnr, nil)
  end)
  state.set_timer(bufnr, timer)
end

---Toggle inline deleted lines display
function M.toggle()
  state.set_enabled(not state.get_enabled())

  if state.get_enabled() then
    M.refresh()
  else
    render.clear()
  end
end

---Expand collapsed hunk at cursor
function M.expand()
  local bufnr = vim.api.nvim_get_current_buf()

  if not M.should_activate(bufnr) then
    vim.notify("Not in a git buffer", vim.log.levels.WARN)
    return
  end

  -- Get hunks for current buffer
  local deleted_hunks = hunks.get_deleted_hunks(bufnr)

  -- Find hunk at cursor
  local hunk = render.find_hunk_at_cursor(bufnr, deleted_hunks)

  if not hunk then
    vim.notify("No collapsed hunk at cursor", vim.log.levels.WARN)
    return
  end

  -- Mark hunk as expanded in state
  state.set_expanded(bufnr, hunk.start_line)

  -- Refresh to show expanded version
  M.refresh(bufnr)

  vim.notify(string.format("Expanded %d deleted lines", #hunk.lines), vim.log.levels.INFO)
end

return M
