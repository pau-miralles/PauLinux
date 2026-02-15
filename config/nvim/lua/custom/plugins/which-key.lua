return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    -- Use a preset for a better default look
    preset = 'modern',
    win = {
      -- Use a floating window with borders
      border = 'rounded', -- none, single, double, shadow, rounded
      padding = { 2, 2, 2, 2 },
    },
    layout = {
      height = { min = 4, max = 25 }, -- min and max height of the columns
      width = { min = 20, max = 50 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
      align = 'center', -- align columns left, center or right
    },
  },
}
