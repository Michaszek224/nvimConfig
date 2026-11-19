-- Autocompletion and snippets.
return {
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = vim.fn.executable 'make' == 1 and 'make install_jsregexp' or nil, -- regex support in snippets
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      -- 'default' preset: <C-y> accept, <C-space> menu/docs, <C-n>/<C-p> select, <C-e> hide, <C-k> signature
      keymap = {
        ['<Tab>'] = { 'select_and_accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        per_filetype = {
          sql = { 'dadbod', inherit_defaults = true },
          mysql = { 'dadbod', inherit_defaults = true },
          plsql = { 'dadbod', inherit_defaults = true },
        },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' }, -- tables/columns from :DBUI connection
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'prefer_rust_with_warning' }, -- prebuilt Rust matcher, Lua fallback
      signature = { enabled = true },
    },
  },
}
