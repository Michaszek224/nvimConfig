-- SQL: database UI and completion. sqlls + sql-formatter are set up in lsp.lua / format.lua.
return {
  {
    'tpope/vim-dadbod',
    dependencies = {
      'kristijanhusak/vim-dadbod-ui',
      'kristijanhusak/vim-dadbod-completion', -- blink source, see completion.lua
    },
    cmd = { 'DBUI', 'DB' },
    keys = {
      { '<leader>db', '<cmd>DBUI<CR>', desc = 'Open [D]ata[B]ase UI' },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
}
