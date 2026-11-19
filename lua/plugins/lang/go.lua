-- Go: extra commands (:GoTest, :GoFillStruct, :GoIfErr, :GoAddTag, ...). gopls is set up in plugins/lsp.lua.
return {
  {
    'ray-x/go.nvim',
    dependencies = { 'ray-x/guihua.lua', 'neovim/nvim-lspconfig', 'nvim-treesitter/nvim-treesitter' },
    ft = { 'go', 'gomod' },
    opts = {},
    build = ':lua require("go.install").update_all_sync()', -- installs Go helper binaries
  },
}
