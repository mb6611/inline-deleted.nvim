-- health.lua - :checkhealth support for inline-deleted.nvim
local M = {}

function M.check()
  vim.health.start("inline-deleted.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 required")
  end

  -- Check gitsigns.nvim
  local has_gitsigns = pcall(require, "gitsigns")
  if has_gitsigns then
    vim.health.ok("gitsigns.nvim found")
  else
    vim.health.error("gitsigns.nvim not found", {
      "Install lewis6991/gitsigns.nvim",
      "This plugin requires gitsigns for git diff data",
    })
  end

  -- Check gitsigns cache API (internal but stable)
  local cache_ok, cache = pcall(require, "gitsigns.cache")
  if cache_ok and cache and cache.cache then
    vim.health.ok("gitsigns cache API available")
  else
    vim.health.warn("gitsigns cache API may have changed", {
      "Update gitsigns.nvim to latest version",
      "Report issue if problem persists",
    })
  end
end

return M
