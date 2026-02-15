return {
  'MagicDuck/grug-far.nvim',
  config = function()
    require('grug-far').setup {}
  end,
  keys = {
    {
      '<leader>fr',
      function()
        -- This opens grug-far and limits the search to the current file.
        require('grug-far').open { prefills = { paths = vim.fn.expand '%' } }
      end,
      desc = 'Find and Replace in Current File',
    },
    {
      '<leader>fa',
      function()
        -- This opens grug-far for searching across all files (default behavior).
        require('grug-far').open()
      end,
      desc = 'Find and Replace in All Files',
    },
  },
}
