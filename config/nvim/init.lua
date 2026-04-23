-- TRANSPARENCY =====================================
local function clear_bg()
  local bgs, get_hl, set_hl = {}, vim.api.nvim_get_hl, vim.api.nvim_set_hl
  for _, g in ipairs({"Normal", "NormalNC", "NormalFloat", "Pmenu", "TelescopeNormal", "SignColumn", "EndOfBuffer"}) do
    local h = get_hl(0, {name=g, link=false})
    if h.bg then bgs[h.bg] = true end
    if h.ctermbg then bgs[h.ctermbg] = true end
    h.bg, h.ctermbg = "NONE", "NONE"; set_hl(0, g, h)
  end

  for n, h in pairs(get_hl(0, {})) do
    if n ~= "CursorLine" and ((h.bg and bgs[h.bg]) or (h.ctermbg and bgs[h.ctermbg])) then
      h.bg, h.ctermbg = "NONE", "NONE"; set_hl(0, n, h)
    end
  end

  for p, l in pairs({ModeNormal="CursorLineNr", ModeInsert="String", ModeVisual="Visual", ModeCommand="DiffAdd", DevInfo="Constant", Fileinfo="Directory", Filename="Normal"}) do
    local h = get_hl(0, {name=l, link=false})
    h.bg, h.ctermbg = "NONE", "NONE"; set_hl(0, "MiniStatusline"..p, h)
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
vim.o.wrap = false           -- Set nowrap
vim.o.linebreak = true       -- Wrap at word boundaries (no mid-word splits)
vim.o.breakindent = true     -- Preserve indentation on wrapped lines
vim.o.scrolloff = 10         -- Keep 10 lines above/below cursor
vim.o.sidescrolloff = 5      -- Keep 5 columns left/right of cursor
vim.o.breakindent = true     -- Better wrapping visualization
vim.o.list = true            -- Show invisible characters
vim.o.confirm = true         -- Ask to save instead of failing
vim.o.inccommand = "split"   -- Live substitution preview
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Must use vim.opt for tables
vim.o.autochdir = true       -- Change directory to current file's

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
vim.opt.foldtext = ""
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
vim.keymap.set('n', '<Esc>', '<cmd>noh<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', { desc = 'Delete Buffer' })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Write buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without replacing clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
vim.cmd('packadd nvim.undotree')
vim.keymap.set('n', '<leader>u', '<cmd>Undotree<CR>', { desc = 'Undotree' })
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

-- Remove extra spaces
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  command = [[%s/\s\+$//e]],
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

-- PLUGINS (NATIVE) ====================================
vim.g.mkdp_filetypes = { "markdown" }        -- Init configs that must run BEFORE plugins load
vim.api.nvim_create_autocmd("PackChanged", { -- 1. Build hooks for external dependencies
  group = vim.api.nvim_create_augroup("NativePluginsBuild", { clear = true }),
  callback = function(ev)
    local name, kind, path = ev.data.spec.name, ev.data.kind, ev.data.path
    if kind == "install" or kind == "update" then
      if name == "markdown-preview.nvim" then
        vim.system({ "yarn", "install", "--frozen-lockfile" }, { cwd = path .. "/app" })
      elseif name == "nvim-treesitter" then
        vim.cmd.packadd("nvim-treesitter")
        vim.cmd("TSUpdate")
        -- Emulate "ensure_installed" natively without a custom command
        vim.cmd("TSInstallSync python nix cpp html css javascript arduino lua vim vimdoc")
      end
    end
  end
})

vim.pack.add({
  "https://github.com/echasnovski/mini.nvim",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/vimpostor/vim-tpipeline",
  "https://github.com/folke/persistence.nvim",
  "https://github.com/folke/flash.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/rachartier/tiny-inline-diagnostic.nvim",
  "https://github.com/iamcco/markdown-preview.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/windwp/nvim-ts-autotag",
  "https://github.com/neovim/nvim-lspconfig",
})

require("gitsigns").setup()
require("tiny-inline-diagnostic").setup()
require('nvim-ts-autotag').setup()

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
MiniStatusline.section_location = function()
  local mode = vim.fn.mode()
  local recording_reg = vim.fn.reg_recording()
  local macro = recording_reg ~= "" and ("󰑊 REC @" .. recording_reg .. " ") or ""
  local visual = ""
  if mode:find('[Vv\22]') then
    local starts = vim.fn.line('v')
    local ends = vim.fn.line('.')
    local lines = math.abs(ends - starts) + 1
    local wc = vim.fn.wordcount()
    local chars = wc.visual_chars or 0
    visual = string.format("[%dL, %dC] ", lines, chars)
  end
  local location = '%l:%v'
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


vim.keymap.set("n", "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>")

local pers = require("persistence")
pers.setup()
vim.keymap.set("n", "<leader>ps", function() pers.load() end, { desc = "Restore Session" })
vim.keymap.set("n", "<leader>pS", function() pers.select() end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>pl", function() pers.load({ last = true }) end, { desc = "Restore Last Session" })
vim.keymap.set("n", "<leader>pd", function() pers.stop() end, { desc = "Don't Save Current Session" })

require("flash").setup({ modes = { char = { enabled = false } } })
vim.keymap.set({ "n", "x", "o" }, "f", function() require("flash").jump() end, { desc = "Flash Jump" })

vim.lsp.enable({
  'pyright',
  'nixd',
  'clangd',
  'html',
  'cssls',
  'arduino_language_server',
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf) -- Attach Treesitter parser
  end,
})
