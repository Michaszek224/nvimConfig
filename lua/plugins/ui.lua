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
        { '<leader>x', group = 'Trouble' },
        { '<leader>g', group = '[G]it' },
        { 'gs', group = 'Surround', mode = { 'n', 'x' } },
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

  { -- Statusline
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = function()
      -- Active Python venv, shown as the project name. Reads venv-selector only if
      -- it is already loaded, so the statusline never forces it to load.
      local function venv()
        local vs = package.loaded['venv-selector']
        local path = (vs and vs.venv()) or vim.env.VIRTUAL_ENV
        if not path or path == '' then
          return ''
        end
        local name = vim.fn.fnamemodify(path, ':t')
        if name == '.venv' or name == 'venv' then
          name = vim.fn.fnamemodify(path, ':h:t')
        end
        return '🐍 ' .. name
      end

      local function lsp_clients()
        local names = vim.tbl_map(function(c)
          return c.name
        end, vim.lsp.get_clients { bufnr = 0 })
        return #names > 0 and (' ' .. table.concat(names, ' ')) or ''
      end

      return {
        options = {
          theme = 'tokyonight',
          globalstatus = true,
          component_separators = '|',
          section_separators = '',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = {
            {
              venv,
              cond = function()
                return vim.bo.filetype == 'python'
              end,
            },
            lsp_clients,
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        extensions = { 'oil', 'trouble', 'lazy', 'mason', 'toggleterm' },
      }
    end,
  },

  { -- Cmdline, messages and notifications as floating popups
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      {
        'rcarriga/nvim-notify',
        -- required with a transparent Normal background, otherwise notify warns on every start
        opts = { background_colour = '#000000' },
      },
    },
    opts = {
      lsp = {
        -- render LSP hover/docs markdown with treesitter
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
        progress = { enabled = true }, -- replaces fidget
        signature = { enabled = false }, -- blink.cmp shows signatures
      },
      routes = {
        { -- pyright reports progress on every didChange (each keystroke); hide it
          filter = {
            event = 'lsp',
            kind = 'progress',
            cond = function(message)
              return vim.tbl_get(message.opts, 'progress', 'client') == 'pyright'
            end,
          },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = true, -- / and ? stay at the bottom
        command_palette = true, -- cmdline and popupmenu together
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },
}
