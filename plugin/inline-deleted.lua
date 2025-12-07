-- plugin/inline-deleted.lua - Plugin entry point for non-lazy.nvim users
-- This file is automatically sourced by Neovim if the plugin is in runtimepath
-- For lazy.nvim users, this file is not needed as setup() is called in the plugin spec

-- Prevent loading if already loaded
if vim.g.loaded_inline_deleted then
  return
end
vim.g.loaded_inline_deleted = true

-- The actual setup is done via require("inline-deleted").setup() in user's config
-- This file just ensures the plugin is marked as loaded
