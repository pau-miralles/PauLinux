-- TRANSPARENCY =====================================
local function clear_bg()
  local bgs, get_hl, set_hl = {}, vim.api.nvim_get_hl, vim.api.nvim_set_hl
  for _, g in ipairs({"Normal", "NormalFloat"}) do
    local h = get_hl(0, {name=g, link=false})
    if h.bg then bgs[h.bg] = true end
    if h.ctermbg then bgs[h.ctermbg] = true end
  end

  for n, h in pairs(get_hl(0, {})) do
    if n ~= "CursorLine" and ((h.bg and bgs[h.bg]) or (h.ctermbg and bgs[h.ctermbg])) then -- Exclude CursorLine
      h.bg, h.ctermbg = nil, nil; set_hl(0, n, h)
    end
  end

  for p, l in pairs({ModeNormal="CursorLineNr", ModeInsert="String", ModeVisual="Visual", ModeCommand="DiffAdd", DevInfo="Constant", Fileinfo="Directory", Filename="Normal"}) do
    local h = get_hl(0, {name=l, link=false})
    h.bg, h.ctermbg = nil, nil; set_hl(0, "MiniStatusline"..p, h)
  end
end
local cb = function() vim.schedule(clear_bg) end
vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"}, {callback=cb})
vim.api.nvim_create_autocmd("User", {pattern="VeryLazy", callback=cb})
clear_bg()

-- BASIC SETTINGS =====================================
vim.o.number = true          -- Line numbers
vim.o.relativenumber = true  -- Relative line numbers
vim.o.cursorline = true      -- Highlight current line
 vim.o.wrap = false          -- set nowrap
vim.o.scrolloff = 10         -- Keep 10 lines above/below cursor
vim.o.sidescrolloff = 5      -- Keep 8 columns left/right of cursor
vim.o.breakindent = true     -- Better wrapping visualization
vim.o.list = true            -- Show invisible characters
vim.o.confirm = true         -- Ask to save instead of failing
vim.o.inccommand = "split"   -- Live substitution preview
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Must use vim.opt for tables

-- Indentation
vim.o.tabstop = 2            -- Tab width
vim.o.shiftwidth = 2         -- Indent width
vim.o.softtabstop = 2        -- Soft tab stop
vim.o.expandtab = true       -- Use spaces instead of tabs

-- Search settings
vim.o.ignorecase = true      -- Case insensitive search
vim.o.smartcase = true       -- Case sensitive if uppercase in search

-- Visual settings
vim.o.winborder = 'single'              -- Global borders: none single double rounded solid shadow
vim.o.signcolumn = "yes"                -- Always show sign column
vim.o.completeopt = "menuone,noinsert"  -- Insert mode completion options
vim.o.synmaxcol = 300                   -- Syntax highlighting limit
vim.opt.fillchars = { eob = " " }       -- Hide ~ on empty lines
vim.o.cmdheight = 0                     -- Hides the command line when not in use

-- File handling
vim.opt.undofile = true
vim.opt.swapfile = true
vim.opt.directory = vim.fn.stdpath("state") .. "/swap//"
vim.opt.shortmess:append("A") -- No annoying popup

-- Behavior settings
vim.opt.iskeyword:append("-")-- Treat dash as part of word
vim.opt.path:append("**")    -- Include subdirectories in search
vim.schedule(function() vim.opt.clipboard:append("unnamedplus") end)

-- Folding settings
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99         -- Start with all folds open
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Split behavior
vim.o.splitbelow = true      -- Horizontal splits go below
vim.o.splitright = true      -- Vertical splits go right

-- Command-line & Diff
vim.o.wildmode = "noselect,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })
vim.opt.diffopt:append("linematch:60")

-- KEY MAPPINGS ====================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', { desc = 'Delete Buffer' })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Write buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without replacing clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
-- Open terminal
vim.keymap.set('n', '<leader>t', function()
  vim.cmd('split')
  vim.cmd('terminal')
  vim.cmd('startinsert')
end, { desc = 'Terminal' })
-- Python run program
vim.keymap.set('n', '<leader>py', function()
  vim.cmd('write')
  if vim.bo.filetype ~= 'python' then
    vim.notify('Not a Python file', vim.log.levels.ERROR)
    return
  end
  local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
  vim.cmd('split')
  vim.cmd('resize ' .. math.floor(vim.o.lines * 0.7))
  vim.cmd('terminal python3 ' .. file)
  vim.cmd('startinsert')
end, { desc = 'Save and run Python file' })

-- AUTOCOMMANDS & FUNCTIONS ====================================
local augroup = vim.api.nvim_create_augroup("UserConfig", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.hl.on_yank() end,
})

-- Return to last edit position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount and vim.bo.filetype ~= "commit" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Tmux Window Renaming
if vim.env.TMUX ~= nil then
  vim.api.nvim_create_autocmd({"BufEnter", "FocusGained"}, {
    group = augroup,
    callback = function()
      local name = vim.fn.expand("%:t")
      if name == "" then name = "[Empty]" end
      vim.fn.system(string.format("tmux rename-window '%s'", name))
    end
  })
  vim.api.nvim_create_autocmd("VimLeave", {
    group = augroup,
    callback = function()
      vim.fn.system("tmux set-window-option automatic-rename on")
    end
  })
end

-- PLUGINS (LAZY.NVIM) ====================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- mini.nvim
  {
    "echasnovski/mini.nvim",
    config = function()
      require('mini.comment').setup()
      require('mini.indentscope').setup()
      require('mini.pairs').setup()
      require('mini.map').setup()
      require('mini.surround').setup()
      require('mini.completion').setup()
      require('mini.cursorword').setup()
      require('mini.move').setup()
      require('mini.cmdline').setup()

      require('mini.statusline').setup()
      MiniStatusline.section_fileinfo = function() return '' end
      MiniStatusline.section_filename = function() return '' end
      MiniStatusline.section_location = function() -- Custom section_location
        local mode = vim.fn.mode()
        local recording_reg = vim.fn.reg_recording() -- Macro recordings
        local macro = recording_reg ~= "" and ("󰑊 REC @" .. recording_reg .. " ") or ""
        local visual = "" -- Selection size
        if mode:find('[Vv\22]') then -- If in Visual, Visual Line, or Visual Block
          local starts = vim.fn.line('v')
          local ends = vim.fn.line('.')
          local lines = math.abs(ends - starts) + 1
          local wc = vim.fn.wordcount() -- Character count
          local chars = wc.visual_chars or 0
          visual = string.format("[%dL, %dC] ", lines, chars)
        end
        local location = '%l:%v' -- Cursor position
        return macro .. visual .. location
      end

      require('mini.tabline').setup({
        format = function(buf_id, label)
          return MiniTabline.default_format(buf_id, label)
            .. (vim.bo[buf_id].modified and '● ' or '')
        end,
      })
      local hipatterns = require('mini.hipatterns')
      hipatterns.setup({
        highlighters = {
          fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
          note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
      local miniclue = require('mini.clue')
      miniclue.setup({
        window = { 
          delay = 0,
          config = { width = 'auto', },
        },
        triggers = {
          { mode = { 'n', 'x' }, keys = '<Leader>' },
          { mode = 'n', keys = '[' },
          { mode = 'n', keys = ']' },
          { mode = 'i', keys = '<C-x>' },
          { mode = { 'n', 'x' }, keys = 'g' },
          { mode = { 'n', 'x' }, keys = "'" },
          { mode = { 'n', 'x' }, keys = '`' },
          { mode = { 'n', 'x' }, keys = '"' },
          { mode = { 'i', 'c' }, keys = '<C-r>' },
          { mode = 'n', keys = '<C-w>' },
          { mode = { 'n', 'x' }, keys = 'z' },
        },
        clues = {
          { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
          { mode = 'n', keys = '<Leader>p', desc = '+Persistence' },
          miniclue.gen_clues.square_brackets(),
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
      })
      local pick = require('mini.pick')
      pick.setup({
        source = {
          show = pick.default_show,
        },
        window = {
          config = function()
            local height = math.floor(0.618 * vim.o.lines)
            local width = math.floor(0.618 * vim.o.columns)
            return {
              anchor = 'NW',
              height = height,
              width = width,
              row = math.floor(0.5 * (vim.o.lines - height)),
              col = math.floor(0.5 * (vim.o.columns - width)),
            }
          end,
        },
      })
      local minifiles = require("mini.files")
      minifiles.setup({
        windows = {
          preview = true,
        },
      })
      vim.keymap.set("n", "<leader>e", function() minifiles.open(vim.api.nvim_buf_get_name(0), true) end, { desc = "File Explorer" })
      vim.keymap.set("n", "<leader><space>", "<cmd>Pick files<cr>", { desc = "Find Files" })
      vim.keymap.set("n", "<leader>f", "<cmd>Pick grep_live<cr>", { desc = "Live Grep" })
      vim.keymap.set("n", "<leader>m", "<Cmd>lua MiniMap.toggle()<CR>", { desc = "Map" })
      vim.keymap.set("n", "<leader>bb", "<cmd>Pick buffers<cr>", { desc = "Show Buffers" })

    end
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    },
  },
  { "vimpostor/vim-tpipeline", },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>ps", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>pS", function() require("persistence").select() end, desc = "Select Session" },
      { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>pd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } }, -- Disables default f/t/s overrides
    keys = {
      { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" }
    }
  },
  -- Git & Diagnostics
  { "lewis6991/gitsigns.nvim", config = true },
  { "rachartier/tiny-inline-diagnostic.nvim", event = "VeryLazy", config = true },
  -- Markdown
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && yarn install --frozen-lockfile",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "python", "nix", "cpp", "html", "css", "javascript", "arduino", "lua", "vim", "vimdoc" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  -- HTML Tags
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable({
        'pyright',
        'nixd',
        'clangd',
        'html',
        'cssls',
        'arduino_language_server',
      })
    end
  }
}, {
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  performance = {
    rtp = {
      reset = false,
    }
  }
})
