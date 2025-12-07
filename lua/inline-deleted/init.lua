-- init.lua - Main module for inline-deleted.nvim
local M = {}

-- Import modules
local config = require("inline-deleted.config")
local state = require("inline-deleted.state")
local core = require("inline-deleted.core")
local autocmds = require("inline-deleted.autocmds")
local render = require("inline-deleted.render")

-- Public API - thin wrappers

--- Toggle inline deleted lines display
function M.toggle()
  core.toggle()
end

--- Expand collapsed hunk at cursor
function M.expand()
  core.expand()
end

--- Refresh deleted line display for a buffer
--- @param bufnr number|nil Buffer number
function M.refresh(bufnr)
  core.refresh(bufnr)
end

-- Private setup functions

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

--- Setup keymaps from config
local function setup_keymaps()
  local cfg = config.get()

  if cfg.keymaps.toggle then
    vim.keymap.set("n", cfg.keymaps.toggle, M.toggle, {
      desc = "Toggle inline deleted",
      silent = true,
    })
  end

  if cfg.keymaps.expand then
    vim.keymap.set("n", cfg.keymaps.expand, M.expand, {
      desc = "Expand deleted hunk",
      silent = true,
    })
  end
end

--- Setup the plugin
--- @param opts table|nil User configuration
function M.setup(opts)
  -- Setup configuration
  config.setup(opts)

  -- Set initial enabled state
  state.set_enabled(config.get().enabled)

  -- Initialize highlight groups
  render.init_highlights()

  -- Setup autocmds with callbacks
  autocmds.setup({
    should_activate = core.should_activate,
    refresh = core.refresh,
    refresh_debounced = core.refresh_debounced,
    clear = render.clear,
    cleanup = state.cleanup_buffer,
  })

  -- Setup user commands
  setup_commands()

  -- Setup keymaps
  setup_keymaps()

  -- Initial refresh for current buffer
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    if core.should_activate(bufnr) then
      core.refresh(bufnr)
    end
  end)
end

return M
