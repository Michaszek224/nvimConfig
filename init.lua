-- Neovim config entry point. Layout and keymaps: see README.md.

-- Leader must be set before lazy.nvim loads plugins.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.lazy'
