# inline-deleted.nvim

A Neovim plugin that shows deleted git lines as inline virtual text below the deletion point.

## Features

- **Inline Display**: Shows deleted lines as red virtual text directly in your buffer
- **Gitsigns Integration**: Uses gitsigns.nvim as the diff data source (unstaged changes only)
- **Smart Collapsing**: Automatically collapses hunks with >100 deleted lines
- **Easy Navigation**: Toggle display and expand collapsed hunks with simple keybindings
- **Minimal Configuration**: Works out of the box with sensible defaults

## UI Example

```
│   3 │ function M.setup(opts)                    │  <- real line
│ ╌╌╌ │ - function M.setup()                      │  <- virtual (red)
│   4 │   M.config = opts or {}                   │  <- real line
│ ╌╌╌ │ - M.config = {}                           │  <- virtual (red)
```

## Requirements

- Neovim >= 0.10
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)

## Installation

### lazy.nvim

```lua
{
  dir = "~/Desktop/code/inline-deleted.nvim",
  dependencies = { "lewis6991/gitsigns.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
  keys = {
    { "<leader>gi", function() require("inline-deleted").toggle() end, desc = "Toggle inline deleted" },
    { "<leader>ge", function() require("inline-deleted").expand() end, desc = "Expand deleted hunk" },
  },
}
```

### packer.nvim

```lua
use {
  "~/Desktop/code/inline-deleted.nvim",
  requires = { "lewis6991/gitsigns.nvim" },
  config = function()
    require("inline-deleted").setup()
  end
}
```

## Configuration

Default configuration:

```lua
require("inline-deleted").setup({
  enabled = true,                -- Enable on startup
  prefix = "- ",                 -- Prefix for deleted lines
  line_marker = "╌╌╌ ",          -- Marker shown in line number column area
  max_lines_expanded = 100,      -- Collapse hunks larger than this
  debounce_ms = 150,             -- Debounce refresh to avoid excessive updates
  keymaps = {
    toggle = "<leader>gi",       -- Toggle inline deleted display
    expand = "<leader>ge",       -- Expand collapsed hunk at cursor
  },
  exclude_filetypes = {          -- Don't activate in these filetypes
    "NvimTree",
    "neo-tree",
    "help",
    "fugitive",
    "git",
  },
})
```

## Usage

### Commands

- `:InlineDeletedToggle` - Toggle inline deleted lines display
- `:InlineDeletedRefresh` - Force refresh inline deleted lines
- `:InlineDeletedExpand` - Expand collapsed hunk at cursor

### Keybindings (default)

- `<leader>gi` - Toggle inline deleted display
- `<leader>ge` - Expand collapsed hunk at cursor

### Workflow

1. Make changes to a git-tracked file
2. Deleted lines automatically appear as red virtual text below the deletion point
3. If a hunk has >100 deleted lines, it shows a collapsed indicator
4. Press `<leader>ge` while on a collapsed hunk to expand it
5. Toggle the entire feature with `<leader>gi`

## Highlight Groups

Customize colors by setting these highlight groups:

```lua
vim.api.nvim_set_hl(0, "InlineDeleted", { fg = "#ff6b6b" })
vim.api.nvim_set_hl(0, "InlineDeletedMarker", { fg = "#666666" })
vim.api.nvim_set_hl(0, "InlineDeletedCollapsed", { fg = "#888888", italic = true })
```

## How It Works

1. **Diff Source**: Integrates with gitsigns.nvim to get unstaged changes
2. **Virtual Text**: Uses Neovim's extmark API with `virt_lines` to render deleted lines
3. **Auto-Refresh**: Automatically updates on buffer changes, saves, and gitsigns updates
4. **State Management**: Tracks collapsed/expanded state per buffer and hunk

## API

```lua
local inline_deleted = require("inline-deleted")

-- Setup with custom config
inline_deleted.setup(opts)

-- Toggle display on/off
inline_deleted.toggle()

-- Force refresh current buffer
inline_deleted.refresh()

-- Expand collapsed hunk at cursor
inline_deleted.expand()
```

## License

MIT
