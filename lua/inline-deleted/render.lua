-- render.lua - Extmark rendering for deleted lines
local M = {}

-- Namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("inline_deleted")

-- State tracking for collapsed hunks per buffer
-- Format: { [bufnr] = { [start_line] = true/false } }
M.collapsed_state = {}

--- Initialize highlight groups
function M.init_highlights()
  vim.api.nvim_set_hl(0, "InlineDeleted", { fg = "#ff6b6b", default = true })
  vim.api.nvim_set_hl(0, "InlineDeletedMarker", { fg = "#666666", default = true })
  vim.api.nvim_set_hl(0, "InlineDeletedCollapsed", { fg = "#888888", italic = true, default = true })
end

--- Clear all extmarks for a buffer
--- @param bufnr number Buffer number
function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Clear collapsed state for this buffer
  M.collapsed_state[bufnr] = nil
end

--- Render a collapsed indicator for a hunk
--- @param bufnr number Buffer number
--- @param line number Line number (1-indexed)
--- @param count number Number of deleted lines
function M.render_collapsed(bufnr, line, count)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Ensure line is within buffer bounds
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line < 0 or line > line_count then
    return
  end

  -- Create collapsed indicator
  local text = string.format("╌╌╌  [%d deleted lines - press <leader>ge to expand]", count)

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_lines = {
      { { text, "InlineDeletedCollapsed" } }
    },
    virt_lines_above = false,
  })
end

--- Render deleted lines as virtual text
--- @param bufnr number Buffer number
--- @param hunks table[] Array of hunks with start_line and lines
--- @param config table Configuration options
function M.render_hunks(bufnr, hunks, config)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Initialize collapsed state for this buffer if needed
  if not M.collapsed_state[bufnr] then
    M.collapsed_state[bufnr] = {}
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for _, hunk in ipairs(hunks) do
    local start_line = hunk.start_line
    local lines = hunk.lines

    -- Skip if line is out of bounds
    if start_line >= 0 and start_line < line_count then
      local num_lines = #lines

      -- Check if this hunk should be collapsed
      local should_collapse = num_lines > config.max_lines_expanded

      -- Check if user has explicitly expanded this hunk
      local is_expanded = M.collapsed_state[bufnr][start_line] == true

      if should_collapse and not is_expanded then
        -- Render collapsed indicator
        M.render_collapsed(bufnr, start_line, num_lines)
        -- Mark as collapsed in state
        M.collapsed_state[bufnr][start_line] = false
      else
        -- Render all deleted lines
        local virt_lines = {}

        for _, line_text in ipairs(lines) do
          -- Create virtual line with marker and deleted text
          table.insert(virt_lines, {
            { config.line_marker, "InlineDeletedMarker" },
            { config.prefix .. line_text, "InlineDeleted" }
          })
        end

        -- Set extmark with virtual lines
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
          virt_lines = virt_lines,
          virt_lines_above = false,
        })

        -- Mark as expanded in state (or not collapsed)
        M.collapsed_state[bufnr][start_line] = is_expanded or not should_collapse
      end
    end
  end
end

--- Find hunk at cursor position
--- @param bufnr number Buffer number
--- @param hunks table[] Array of hunks
--- @return table|nil Hunk at cursor or nil
function M.find_hunk_at_cursor(bufnr, hunks)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1] - 1 -- Convert to 0-indexed

  for _, hunk in ipairs(hunks) do
    -- Check if cursor is on or near the hunk start line
    -- Allow a small range since virtual lines appear below
    if math.abs(hunk.start_line - cursor_line) <= 1 then
      return hunk
    end
  end

  return nil
end

return M
