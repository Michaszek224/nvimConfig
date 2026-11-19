-- Installs everything the smoke test needs, synchronously: plugins, mason tools, treesitter parsers.
-- Run via tests/run.sh.
vim.cmd 'Lazy! install'
vim.cmd 'MasonToolsInstallSync'

local spec = require('lazy.core.config').plugins['nvim-treesitter']
local opts = require('lazy.core.plugin').values(spec, 'opts', false)
require('nvim-treesitter').install(opts.ensure_installed):wait(600000)

vim.cmd 'qall!'
