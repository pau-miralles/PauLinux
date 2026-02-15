return {
  -- Auto close/rename HTML tags
  {
    'windwp/nvim-ts-autotag',
    opts = {},
  },
  
  -- Show colors for hex codes (e.g. #ffffff)
  {
    'NvChad/nvim-colorizer.lua',
    opts = {
      user_default_options = {
        tailwind = true, -- if you use tailwind later
        css = true,
      }
    }
  }
}
