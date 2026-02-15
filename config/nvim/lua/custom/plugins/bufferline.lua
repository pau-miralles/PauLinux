return {
  'akinsho/bufferline.nvim',
  event = 'VimEnter',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = {
      -- Use a modern, clean separator style
      separator_style = 'thin',

      -- Disable icons and indicators for a cleaner look
      show_buffer_close_icons = false,
      show_close_icon = false,
      show_tab_indicators = false,

      -- Add a slight offset for a file explorer like nvim-tree
      offsets = {
        {
          filetype = 'NvimTree',
          text = 'File Explorer',
          text_align = 'left',
          separator = true,
        },
      },

      -- Show LSP diagnostics as simple icons without counts
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = function(_, level)
        local icon = level:match 'error' and '●' or (level:match 'warning' and '●' or '')
        if icon ~= '' then
          return icon
        end
        return ''
      end,
    },
  },
}
