return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  ---@type Flash.Config
  opts = {
    modes = {
      char = {
        -- disable the default f motion
        keys = { 't', 'T', ';', ',' },
      },
    },
  },
  keys = {
    {
      'f',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump()
      end,
      desc = 'Flash Jump',
    },
    -- You can now remove or remap the 's' keybinding
    -- For example, to disable it:
    { 's', mode = { 'n', 'x', 'o' }, false },
  },
}
