-- Editor options. See `:help option-list`.
local o = vim.o

o.number = true
o.relativenumber = true
o.mouse = 'a'
o.showmode = false -- mode is shown in the statusline
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true -- case-sensitive once the pattern has a capital letter
o.signcolumn = 'yes'
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.inccommand = 'split' -- live preview of :s
o.cursorline = true
o.scrolloff = 10
o.confirm = true -- ask to save instead of failing on :q

-- Indentation: 4 spaces by default (guess-indent adapts per file).
-- C/C++ indent comes from the built-in cindent (indent/c.vim).
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true

-- Sync with the system clipboard; scheduled because the provider check slows startup.
vim.schedule(function()
  o.clipboard = 'unnamedplus'
end)
