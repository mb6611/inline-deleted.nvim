-- hunks.lua - Gitsigns integration for retrieving deleted lines
local M = {}

--- Check if a buffer is in a git repository
--- @param bufnr number Buffer number
--- @return boolean
function M.is_git_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check if gitsigns is loaded
  local gitsigns = package.loaded.gitsigns
  if not gitsigns then
    return false
  end

  -- Check if buffer is attached to gitsigns using buffer variable
  -- gitsigns sets vim.b.gitsigns_head when it attaches to a buffer
  return vim.b[bufnr].gitsigns_head ~= nil
end

--- Get hunks with deleted lines from gitsigns
--- @param bufnr number Buffer number
--- @return table[] Array of hunks: { { start_line = number, lines = string[] }, ... }
function M.get_deleted_hunks(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Verify it's a git buffer
  if not M.is_git_buffer(bufnr) then
    return {}
  end

  -- Get hunks from gitsigns using the cache (internal but stable API)
  local status_ok, cache = pcall(require, "gitsigns.cache")
  if not status_ok or not cache then
    return {}
  end

  local bcache = cache.cache[bufnr]
  if not bcache or not bcache.hunks then
    return {}
  end

  local hunks = bcache.hunks

  -- Process hunks to extract deleted lines
  local deleted_hunks = {}

  for _, hunk in ipairs(hunks) do
    -- Gitsigns hunk structure: { type = "delete"|"change"|"add", removed = { start, count, lines }, added = { start, count } }
    -- Check if this hunk has deleted lines
    if hunk.removed and hunk.removed.lines and #hunk.removed.lines > 0 then
      -- For deletions, position them at the line where deletion occurred
      -- For changes, position at the start of the added section
      local position_line = hunk.added.start

      -- If it's a pure deletion (no added lines), position at the line before deletion
      if hunk.type == "delete" then
        position_line = hunk.removed.start - 1
        -- Ensure we don't go negative
        if position_line < 0 then
          position_line = 0
        end
      end

      table.insert(deleted_hunks, {
        start_line = position_line,
        lines = hunk.removed.lines,
        hunk_type = hunk.type,
      })
    end
  end

  return deleted_hunks
end

return M
