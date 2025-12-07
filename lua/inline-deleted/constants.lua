-- constants.lua - Enums and default values for inline-deleted.nvim
local M = {}

-- Highlight group names
M.Highlights = {
  DELETED = "InlineDeleted",
  MARKER = "InlineDeletedMarker",
  COLLAPSED = "InlineDeletedCollapsed",
}

-- Namespace for extmarks
M.Namespace = "inline_deleted"

return M
