vim.g.have_nerd_font = true
-- transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none", fg = "#767676" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "none" })

-- BASIC SETTINGS =====================================
vim.o.number = true            -- Line numbers
vim.o.relativenumber = true    -- Relative line numbers
vim.o.cursorline = true        -- Highlight current line
 vim.o.wrap = false            -- set nowrap
vim.o.scrolloff = 10           -- Keep 10 lines above/below cursor 
vim.o.sidescrolloff = 8        -- Keep 8 columns left/right of cursor
vim.o.breakindent = true       -- Better wrapping visualization
vim.o.list = true              -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Must use vim.opt for tables
vim.o.confirm = true           -- Ask to save instead of failing
vim.o.inccommand = "split"     -- Live substitution preview

-- Indentation
vim.o.tabstop = 4              -- Tab width
vim.o.shiftwidth = 4           -- Indent width
vim.o.softtabstop = 4          -- Soft tab stop
vim.o.expandtab = true         -- Use spaces instead of tabs
vim.o.smartindent = true       -- Smart auto-indenting

-- Search settings
vim.o.ignorecase = true        -- Case insensitive search
vim.o.smartcase = true         -- Case sensitive if uppercase in search

-- Visual settings
vim.o.winborder = 'single'                       -- Global borders none single double rounded solid shadow
vim.o.termguicolors = true                       -- True color support
vim.o.signcolumn = "yes"                         -- Always show sign column
vim.o.completeopt = "menuone,noinsert,noselect"  -- Completion options 
vim.o.showmode = false                           -- Don't show mode in command line 
vim.o.lazyredraw = true                          -- Don't redraw during macros
vim.o.synmaxcol = 300                            -- Syntax highlighting limit 
vim.opt.fillchars = { eob = " " }                -- Hide ~ on empty lines
vim.o.cmdheight = 0                              -- Hides the command line when not in use

-- File handling
vim.o.writebackup = false      -- Don't create backup before writing
vim.o.swapfile = false         -- Don't create swap files
vim.o.undofile = true          -- Persistent undo
vim.o.updatetime = 250         -- Faster completion
vim.o.timeoutlen = 300         -- Key timeout duration
vim.o.ttimeoutlen = 0          -- Key code timeout

-- Behavior settings
vim.opt.iskeyword:append("-")  -- Treat dash as part of word
vim.opt.path:append("**")      -- Include subdirectories in search
vim.o.selection = "exclusive"  -- Selection behavior
vim.o.mouse = "a"              -- Enable mouse support
vim.schedule(function() vim.opt.clipboard:append("unnamedplus") end)

vim.o.guicursor = "n-v-c:block,i-ci-r:ver25,cr-o:hor20" -- Cursor

-- Folding settings
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99           -- Start with all folds open
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Split behavior
vim.o.splitbelow = true        -- Horizontal splits go below
vim.o.splitright = true        -- Vertical splits go right

-- Command-line & Diff
vim.o.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })
vim.opt.diffopt:append("linematch:60")
vim.o.redrawtime = 10000
vim.o.maxmempattern = 20000

-- KEY MAPPINGS ====================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = '[Q]uit buffer' })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = '[W]rite buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result" })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without replacing clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
-- Window & Split Navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })
vim.keymap.set('n', '<leader>-', '<cmd>split<CR>', { desc = 'New horizontal split' })
vim.keymap.set('n', '<leader>|', '<cmd>vsplit<CR>', { desc = 'New vertical split' })
-- Line movement & Indent
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })
-- Python run program
vim.keymap.set('n', '<leader>py', function()
  vim.cmd('write')
  if vim.bo.filetype ~= 'python' then
    vim.notify('Not a Python file', vim.log.levels.ERROR)
    return
  end
  local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
  vim.cmd('botright split')
  vim.cmd('resize ' .. math.floor(vim.o.lines * 0.7))
  vim.cmd('terminal python3 ' .. file)
  vim.cmd('startinsert')
end, { desc = 'Save and run [P]ython file' })

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

-- Filetype indents
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "lua", "python" },
  callback = function()
    vim.bo.tabstop, vim.bo.shiftwidth = 4, 4
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "javascript", "typescript", "json", "html", "css" },
  callback = function()
    vim.bo.tabstop, vim.bo.shiftwidth = 2, 2
  end,
})

-- Terminal management
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then vim.api.nvim_buf_delete(0, {}) end
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.o.number, vim.o.relativenumber, vim.o.signcolumn = false, false, "no"
  end,
})

-- Auto-resize splits & Create dirs
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function() vim.cmd("wincmd =") end,
})
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    local dir = vim.fn.fnamemodify(args.file, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
  end,
})

-- FLOATING TERMINAL ====================================
local term_state = { buf = nil, win = nil, is_open = false }
local function FloatingTerminal()
  if term_state.is_open and vim.api.nvim_win_is_valid(term_state.win) then
    vim.api.nvim_win_close(term_state.win, false)
    term_state.is_open = false
    return
  end
  if not term_state.buf or not vim.api.nvim_buf_is_valid(term_state.buf) then
    term_state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[term_state.buf].bufhidden = 'hide'
  end
  local w, h = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.9)
  term_state.win = vim.api.nvim_open_win(term_state.buf, true, {
    relative = 'editor', width = w, height = h,
    row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2),
    -- style = 'minimal', border = 'rounded',
  })
  vim.wo[term_state.win].winblend = 0
  if vim.api.nvim_buf_line_count(term_state.buf) == 1 and vim.api.nvim_buf_get_lines(term_state.buf, 0, 1, false)[1] == "" then
    vim.fn.termopen(os.getenv("SHELL"))
  end
  term_state.is_open = true
  vim.cmd("startinsert")
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = term_state.buf,
    callback = function()
      if term_state.is_open and vim.api.nvim_win_is_valid(term_state.win) then
        vim.api.nvim_win_close(term_state.win, false)
        term_state.is_open = false
      end
    end,
    once = true
  })
end

vim.keymap.set("n", "<leader>t", FloatingTerminal, { desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", function()
  if term_state.is_open then
    vim.api.nvim_win_close(term_state.win, false)
    term_state.is_open = false
  end
end, { desc = "Close floating terminal" })

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
      require('mini.ai').setup()
      require('mini.bufremove').setup()
      require('mini.comment').setup()
      require('mini.indentscope').setup()
      require('mini.pairs').setup()
      require('mini.statusline').setup()
      require('mini.surround').setup()
      -- Setup Mini.clue (Which-key alternative)
      local miniclue = require('mini.clue')
      miniclue.setup({
        window = { delay = 0 },
        triggers = {
          { mode = 'n', keys = '<Leader>' }, { mode = 'x', keys = '<Leader>' },
          { mode = 'n', keys = 'g' },        { mode = 'x', keys = 'g' },
          { mode = 'n', keys = "'" },        { mode = 'n', keys = '`' },
          { mode = 'n', keys = '"' },        { mode = 'x', keys = '"' },
          { mode = 'n', keys = '<C-w>' },
        },
        clues = {
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
      })
    end
  },
  -- Bufferline
  { "akinsho/bufferline.nvim", dependencies = "nvim-tree/nvim-web-devicons", config = true },
  -- Flash
  {
    "folke/flash.nvim", 
    opts = { modes = { char = { enabled = false } } }, -- Disables default f/t/s overrides
    keys = { 
      { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" } 
    } 
  },
  -- Neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    keys = { { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" } }
  },
  -- Telescope
  {
    "nvim-telescope/telescope.nvim", 
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>f", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    }
  },
  -- Git & Diagnostics
  { "lewis6991/gitsigns.nvim", config = true },
  { "rachartier/tiny-inline-diagnostic.nvim", event = "VeryLazy", config = true },
  -- Colorizer & Markdown
  { "norcalli/nvim-colorizer.lua", config = true },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- <-- ADD THIS LINE
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "python", "nix", "cpp", "html", "css", "javascript", "arduino", "lua", "vim", "vimdoc" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
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
        'ts_ls',
        'arduino_language_server'
      })
      -- Auto-setup keybinds when LSP attaches to a buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts, { desc = "Go to definition" })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts, { desc = "Hover documentation" })
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts, { desc = "Rename symbol" })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts, { desc = "Code action" })
        end
      })
    end
  }
}, {
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})
