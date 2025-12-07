-- init.lua - Main module for inline-deleted.nvim
local M = {}

-- Submodules
local hunks = require("inline-deleted.hunks")
local render = require("inline-deleted.render")

-- Default configuration
M.defaults = {
  enabled = true,
  prefix = "- ",
  line_marker = "╌╌╌ ",
  max_lines_expanded = 100,
  debounce_ms = 150,
  keymaps = {
    toggle = "<leader>gi",
    expand = "<leader>ge",
  },
  exclude_filetypes = { "NvimTree", "neo-tree", "help", "fugitive", "git" },
}

-- Plugin state
M.config = {}
M.enabled = true

-- Debounce timer for refresh
local refresh_timer = nil

--- Check if plugin should be active for current buffer
--- @param bufnr number|nil Buffer number
--- @return boolean
local function should_activate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not M.enabled then
    return false
  end

  -- Check filetype exclusions
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  for _, excluded in ipairs(M.config.exclude_filetypes) do
    if ft == excluded then
      return false
    end
  end

  -- Check if it's a git buffer
  return hunks.is_git_buffer(bufnr)
end

--- Refresh deleted line display for a buffer
--- @param bufnr number|nil Buffer number
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear existing extmarks
  render.clear(bufnr)

  -- Check if we should activate for this buffer
  if not should_activate(bufnr) then
    return
  end

  -- Get deleted hunks from gitsigns
  local deleted_hunks = hunks.get_deleted_hunks(bufnr)

  -- Render the hunks
  render.render_hunks(bufnr, deleted_hunks, M.config)
end

--- Debounced refresh to avoid excessive updates
--- @param bufnr number|nil Buffer number
local function refresh_debounced(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Cancel existing timer
  if refresh_timer then
    vim.fn.timer_stop(refresh_timer)
  end

  -- Start new timer
  refresh_timer = vim.fn.timer_start(M.config.debounce_ms, function()
    M.refresh(bufnr)
    refresh_timer = nil
  end)
end

--- Toggle inline deleted lines display
function M.toggle()
  M.enabled = not M.enabled

  if M.enabled then
    vim.notify("Inline deleted: enabled", vim.log.levels.INFO)
    M.refresh()
  else
    vim.notify("Inline deleted: disabled", vim.log.levels.INFO)
    -- Clear all extmarks from current buffer
    render.clear()
  end
end

--- Expand collapsed hunk at cursor
function M.expand()
  local bufnr = vim.api.nvim_get_current_buf()

  if not should_activate(bufnr) then
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
  if not render.collapsed_state[bufnr] then
    render.collapsed_state[bufnr] = {}
  end
  render.collapsed_state[bufnr][hunk.start_line] = true

  -- Refresh to show expanded version
  M.refresh(bufnr)

  vim.notify(string.format("Expanded %d deleted lines", #hunk.lines), vim.log.levels.INFO)
end

--- Setup autocommands for automatic refresh
local function setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("InlineDeleted", { clear = true })

  -- Refresh on buffer changes
  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
    group = augroup,
    callback = function(args)
      if should_activate(args.buf) then
        refresh_debounced(args.buf)
      end
    end,
    desc = "Refresh inline deleted lines on buffer changes",
  })

  -- Refresh when entering a buffer
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function(args)
      if should_activate(args.buf) then
        M.refresh(args.buf)
      end
    end,
    desc = "Refresh inline deleted lines when entering buffer",
  })

  -- Clear when leaving buffer
  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    callback = function(args)
      render.clear(args.buf)
    end,
    desc = "Clear inline deleted lines when leaving buffer",
  })

  -- Refresh on gitsigns updates (if available)
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "GitSignsUpdate",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if should_activate(bufnr) then
        refresh_debounced(bufnr)
      end
    end,
    desc = "Refresh inline deleted lines on gitsigns update",
  })
end

--- Setup user commands
local function setup_commands()
  vim.api.nvim_create_user_command("InlineDeletedToggle", function()
    M.toggle()
  end, {
    desc = "Toggle inline deleted lines display",
  })

  vim.api.nvim_create_user_command("InlineDeletedRefresh", function()
    M.refresh()
  end, {
    desc = "Force refresh inline deleted lines",
  })

  vim.api.nvim_create_user_command("InlineDeletedExpand", function()
    M.expand()
  end, {
    desc = "Expand collapsed hunk at cursor",
  })
end

--- Setup keymaps
local function setup_keymaps()
  if M.config.keymaps.toggle then
    vim.keymap.set("n", M.config.keymaps.toggle, M.toggle, {
      desc = "Toggle inline deleted",
      silent = true,
    })
  end

  if M.config.keymaps.expand then
    vim.keymap.set("n", M.config.keymaps.expand, M.expand, {
      desc = "Expand deleted hunk",
      silent = true,
    })
  end
end

--- Setup the plugin
--- @param opts table|nil User configuration
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Set initial enabled state from config
  M.enabled = M.config.enabled

  -- Initialize highlight groups
  render.init_highlights()

  -- Setup autocommands
  setup_autocmds()

  -- Setup user commands
  setup_commands()

  -- Setup keymaps
  setup_keymaps()

  -- Initial refresh for current buffer
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    if should_activate(bufnr) then
      M.refresh(bufnr)
    end
  end)
end

return M
