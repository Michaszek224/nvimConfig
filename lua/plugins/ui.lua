-- Colorscheme, keymap hints and visual helpers.
return {
  { -- Colorscheme (transparent background)
    'folke/tokyonight.nvim',
    priority = 1000, -- load before other start plugins
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        transparent = true,
        styles = {
          comments = { italic = false },
          floats = 'transparent',
          sidebars = 'transparent',
        },
      }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  { -- Shows pending keybinds
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>c', group = '[C]ode' },
        { '<leader>d', group = '[D]atabase' },
      },
    },
  },

  { -- Highlight TODO/NOTE/FIXME in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  { -- Indentation guides
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },
}
