return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- This is the crucial line to add
    build = ':TSUpdate',
    config = function()
      -- This line will now work again
      local configs = require 'nvim-treesitter.configs'

      configs.setup({
        ensure_installed = { 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline', 'python', 'javascript' },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
