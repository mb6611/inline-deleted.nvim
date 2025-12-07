---@class InlineDeleted.Keymaps
---@field toggle string Keymap to toggle inline deleted lines display
---@field expand string Keymap to expand/collapse deleted hunks

---@class InlineDeleted.Config
---@field enabled boolean Whether the plugin is enabled
---@field prefix string Prefix shown before each deleted line
---@field line_marker string Marker shown for collapsed deleted hunks
---@field max_lines_expanded number Maximum number of deleted lines to show when expanded
---@field debounce_ms number Debounce time in milliseconds for updates
---@field keymaps InlineDeleted.Keymaps Keymap configuration
---@field exclude_filetypes string[] Filetypes to exclude from inline deleted lines

local M = {}

---Default configuration values
---@type InlineDeleted.Config
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

---Current merged configuration (initialized on setup)
---@type InlineDeleted.Config?
M.config = nil

---Setup the configuration by merging user options with defaults
---@param opts InlineDeleted.Config? User configuration options
---@return InlineDeleted.Config config The merged configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.config
end

---Get the current configuration
---@return InlineDeleted.Config config The current configuration
function M.get()
  return M.config or M.defaults
end

return M
