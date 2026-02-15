-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.
  --

  -- modular approach: using `require 'path.name'` will
  -- include a plugin definition from file lua/path/name.lua

  require 'kickstart.plugins.gitsigns',

  require 'kickstart.plugins.which-key',

  require 'kickstart.plugins.telescope',

  require 'kickstart.plugins.lspconfig',

  require 'kickstart.plugins.conform',

  require 'kickstart.plugins.blink-cmp',

  require 'kickstart.plugins.todo-comments',

  require 'kickstart.plugins.mini',

  require 'kickstart.plugins.treesitter',

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- =============================================================================
-- BICROME THEME
-- =============================================================================
local function set_bicrome_colors()
  vim.opt.termguicolors = true
  vim.cmd.hi 'clear'

  -- 1. Define Palettes for Dark and Light modes
  local palettes = {
    dark = {
      bg0 = '#32302f', -- Primary Background
      bg1 = '#453030', -- UI Background
      bg_selection = '#da8f7c',
      fg0 = '#e9d2bf', -- Primary Foreground
      fg1 = '#d8cdb2', -- Lighter Foreground
      fg_comment = '#817663',
      red = '#e56461',
      red_bright = '#eb6c69',
      orange = '#efac77',
      yellow = '#efd777',
      green = '#a4b77a',
      purple = '#d17b9d',
      border = '#817663',
    },
    light = {
      -- Inverted "Warm Paper" Palette
      bg0 = '#faf4ed', -- Warm/White Background
      bg1 = '#f2e9e1', -- Slightly darker UI background
      bg_selection = '#f4d0c9', -- Soft pink/red selection
      fg0 = '#5c4f49', -- Dark warm grey text
      fg1 = '#7c6f64', -- Softer text
      fg_comment = '#a89984',
      -- Accents (Darkened slightly for readability on light bg)
      red = '#c34043',
      red_bright = '#e56461',
      orange = '#d65d0e',
      yellow = '#b57614',
      green = '#6f8352',
      purple = '#8f3f71',
      border = '#d5c4a1',
    },
  }

  -- 2. Select palette based on current background setting
  -- If vim.o.background is 'light', use light, otherwise use dark
  local p = vim.o.background == 'light' and palettes.light or palettes.dark

  local highlights = {
    -- Core Editor UI
    Normal = { fg = p.fg0, bg = 'NONE' }, -- Keep NONE so Kitty's bg shows through
    SignColumn = { bg = 'NONE' },
    CursorLine = { bg = p.bg1 },
    Visual = { bg = p.bg_selection, fg = p.light and p.fg0 or p.bg0, bold = true },
    LineNr = { fg = p.fg_comment },
    CursorLineNr = { fg = p.yellow, bold = true },
    ColorColumn = { bg = p.bg1 },
    EndOfBuffer = { fg = p.bg0 },

    -- Window & Tab UI
    StatusLine = { fg = p.fg1, bg = p.bg1 },
    StatusLineNC = { fg = p.fg_comment, bg = p.bg1 },
    TabLine = { fg = p.fg_comment, bg = p.bg1 },
    TabLineSel = { fg = p.fg0, bg = p.red_bright, bold = true },
    TabLineFill = { bg = p.bg1 },
    WinSeparator = { fg = p.border, bold = true },

    -- Syntax Highlighting
    Comment = { fg = p.fg_comment, italic = true },

    -- Primary: Keywords are red
    Keyword = { fg = p.red, bold = true },
    Statement = { fg = p.red, bold = true },
    Conditional = { fg = p.red, bold = true },
    Repeat = { fg = p.red, bold = true },
    Exception = { fg = p.red, bold = true },
    Include = { fg = p.red, bold = true },

    -- Secondary: Types, Operators are orange
    Type = { fg = p.orange, italic = true },
    Operator = { fg = p.orange },
    Constant = { fg = p.orange },
    PreProc = { fg = p.orange },

    -- Tertiary: Functions are bright yellow
    Function = { fg = p.yellow, bold = true },
    Title = { fg = p.yellow, bold = true },
    Label = { fg = p.yellow },
    Macro = { fg = p.yellow },

    -- Low Importance
    Identifier = { fg = p.fg1 },
    String = { fg = p.fg1 },
    Character = { fg = p.fg1 },

    -- Distinct data types
    Number = { fg = p.purple },
    Boolean = { fg = p.purple },

    -- Special cases
    Special = { fg = p.green },
    Todo = { fg = p.green, bg = p.bg1, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.orange },
    DiagnosticInfo = { fg = p.yellow },
    DiagnosticHint = { fg = p.purple },

    -- Git
    GitSignsAdd = { fg = p.green },
    GitSignsChange = { fg = p.yellow },
    GitSignsDelete = { fg = p.red },

    -- Common Plugins
    TelescopeBorder = { fg = p.red },
    WhichKey = { fg = p.orange },
  }

  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end
end

-- 3. Create an Autocmd to watch for background changes
-- This detects when you do ":set background=light" or if an OS script changes it
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function()
    set_bicrome_colors()
  end,
})

set_bicrome_colors()
-- =============================================================================

-- vim: ts=2 sts=2 sw=2 et
