-- Syntax trees: highlighting, indentation, sticky context header.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'rust', 'toml' },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true, disable = { 'c', 'cpp' } }, -- C/C++ use cindent
    },
  },

  { -- Shows the enclosing function/class at the top of the window
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPre',
    opts = {
      max_lines = 3,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = '-',
    },
  },
}
