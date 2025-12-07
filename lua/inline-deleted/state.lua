-- state.lua - Centralized state management for inline-deleted.nvim
local M = {}

-- Internal state (private)
local _state = {
  enabled = true,
  timers = {},     -- { [bufnr] = timer_id }
  collapsed = {},  -- { [bufnr] = { [line] = bool } }
}

---Get enabled state
---@return boolean
function M.get_enabled()
  return _state.enabled
end

---Set enabled state
---@param enabled boolean
function M.set_enabled(enabled)
  _state.enabled = enabled
end

---Get timer for a buffer
---@param bufnr number
---@return number|nil timer_id
function M.get_timer(bufnr)
  return _state.timers[bufnr]
end

---Set timer for a buffer
---@param bufnr number
---@param timer number|nil
function M.set_timer(bufnr, timer)
  _state.timers[bufnr] = timer
end

---Clear and stop timer for a buffer
---@param bufnr number
function M.clear_timer(bufnr)
  local timer = _state.timers[bufnr]
  if timer then
    vim.fn.timer_stop(timer)
  end
  _state.timers[bufnr] = nil
end

---Get collapsed state for a buffer
---@param bufnr number
---@return table { [line] = bool }
function M.get_collapsed(bufnr)
  return _state.collapsed[bufnr] or {}
end

---Mark a hunk as expanded
---@param bufnr number
---@param line number
function M.set_expanded(bufnr, line)
  if not _state.collapsed[bufnr] then
    _state.collapsed[bufnr] = {}
  end
  _state.collapsed[bufnr][line] = true
end

---Clear collapsed state for a buffer
---@param bufnr number
function M.clear_collapsed(bufnr)
  _state.collapsed[bufnr] = nil
end

---Cleanup all state for a buffer (call on BufDelete)
---@param bufnr number
function M.cleanup_buffer(bufnr)
  M.clear_timer(bufnr)
  M.clear_collapsed(bufnr)
end

return M
