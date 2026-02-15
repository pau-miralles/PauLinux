return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('ibl').setup {
        -- You can add other configurations here, for example:
        indent = {
          char = '▏', -- Change the indent character
        },
      }
    end,
  },
}
