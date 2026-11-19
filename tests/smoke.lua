-- Headless smoke test for this config.
-- Run via `bash tests/run.sh` (prints PASS/FAIL per check, exit code 1 on any FAIL).

local failed = false
local function report(ok, name, detail)
  if not ok then
    failed = true
  end
  io.stdout:write(('%s %s %s\n'):format(ok and 'PASS' or 'FAIL', name, detail or ''))
end

local function error_lines()
  local out = {}
  for _, line in ipairs(vim.split(vim.fn.execute 'messages', '\n')) do
    if line:match 'E%d+:' or line:match 'Error' or line:match 'stack traceback' or line:match '[Ww]arn' then
      table.insert(out, line)
    end
  end
  return out
end

-- Fixtures -------------------------------------------------------------------
local root = vim.fn.tempname()
local function write(rel, content)
  local path = root .. '/' .. rel
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile(vim.split(content, '\n'), path)
  return path
end

write('go/go.mod', 'module x\n\ngo 1.22')
write('rs/Cargo.toml', '[package]\nname = "x"\nversion = "0.1.0"\nedition = "2021"')

local fixtures = {
  { 'c/main.c', 'int main(void) { return 0; }', { 'clangd' } },
  { 'py/main.py', 'import os\nprint(os.getcwd())', { 'pyright', 'ruff' } },
  { 'go/main.go', 'package main\n\nfunc main() {}', { 'gopls' } },
  { 'rs/src/main.rs', 'fn main() {}', { 'rust_analyzer' } },
  { 'q.sql', 'select 1;', { 'sqlls' } },
  { 'compose.yaml', 'services:\n  web:\n    image: nginx', { 'yamlls', 'docker_language_server' } },
  { 'Dockerfile', 'FROM alpine:3.20', { 'docker_language_server' } },
  { 'x.json', '{ "a": 1 }', { 'jsonls' } },
  { 'x.lua', 'local a = 1', { 'lua_ls' } },
  { 'README.md', '# Title\n\ntext', {} },
}

-- Startup messages -------------------------------------------------------------
vim.wait(2000)
local startup_errors = error_lines()
report(#startup_errors == 0, 'messages_clean', table.concat(startup_errors, ' | '))

-- LSP clients + treesitter per filetype ------------------------------------------
for _, fx in ipairs(fixtures) do
  local rel, content, want = fx[1], fx[2], fx[3]
  vim.cmd.edit(vim.fn.fnameescape(write(rel, content)))
  local buf = vim.api.nvim_get_current_buf()

  local function attached()
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients { bufnr = buf }) do
      names[c.name] = true
    end
    return names
  end
  vim.wait(30000, function()
    local names = attached()
    for _, w in ipairs(want) do
      if not names[w] then
        return false
      end
    end
    return true
  end, 200)

  local names = attached()
  local missing = vim.tbl_filter(function(w)
    return not names[w]
  end, want)
  report(#missing == 0, 'lsp:' .. rel, (#missing > 0 and 'missing=' .. table.concat(missing, ',') or '') .. ' ft=' .. vim.bo[buf].filetype)

  local ts_ok = vim.wait(5000, function()
    return vim.treesitter.highlighter.active[buf] ~= nil
  end, 100)
  report(ts_ok, 'treesitter:' .. rel, 'ft=' .. vim.bo[buf].filetype)
end

-- Plugins ------------------------------------------------------------------------
local plugins = require('lazy.core.config').plugins
local absent = { 'supermaven-nvim', 'csv.vim', 'yaml.nvim', 'neo-tree.nvim', 'nvim-dev-container', 'fidget.nvim' }
local present = {
  'oil.nvim',
  'flash.nvim',
  'trouble.nvim',
  'lazygit.nvim',
  'diffview-plus.nvim',
  'lualine.nvim',
  'noice.nvim',
  'nvim-notify',
  'render-markdown.nvim',
  'SchemaStore.nvim',
}
local ts_spec = plugins['nvim-treesitter'] or {}
report(ts_spec.branch == 'main', 'treesitter_main_branch', 'branch=' .. tostring(ts_spec.branch))
local legacy_parsers = vim.fn.glob(vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/parser/*.so', false, true)
report(#legacy_parsers == 0, 'treesitter_no_legacy_parsers', #legacy_parsers .. ' old master-branch parsers on rtp')

local still = vim.tbl_filter(function(n)
  return plugins[n] ~= nil
end, absent)
report(#still == 0, 'plugins_absent', table.concat(still, ','))
local lacking = vim.tbl_filter(function(n)
  return plugins[n] == nil
end, present)
report(#lacking == 0, 'plugins_present', table.concat(lacking, ','))

-- Keymaps ------------------------------------------------------------------------
-- { mode, lhs, optional Lua pattern the mapping's desc must match }
local keymaps = {
  { 'n', 's', 'Flash' },
  { 'x', 's', 'Flash' },
  { 'n', 'S', 'Flash' },
  { 'n', 'gsa', '[Ss]urround' },
  { 'n', '-' },
  { 'n', '<leader>gg' },
  { 'n', '<leader>gd' },
  { 'n', '<leader>gh' },
  { 'n', '<leader>xx' },
  { 'n', '<leader>tm' },
  { 'n', '<leader>sf' },
  { 'n', '<leader>f' },
  { 'n', '<C-/>' },
}
for _, km in ipairs(keymaps) do
  local m = vim.fn.maparg(km[2], km[1], false, true)
  local ok = not vim.tbl_isempty(m) and (km[3] == nil or (m.desc or ''):match(km[3]) ~= nil)
  report(ok, ('keymap:%s:%s'):format(km[1], km[2]), m.desc or '')
end

-- Directory buffer opens oil ------------------------------------------------------------
vim.cmd.edit(vim.fn.fnameescape(root))
local is_oil = vim.wait(5000, function()
  return vim.bo.filetype == 'oil'
end, 100)
report(is_oil, 'dir_opens_oil', 'ft=' .. vim.bo.filetype)

-- Buffers without a treesitter parser must not raise errors ---------------------------------
local before = #error_lines()
vim.cmd.edit(vim.fn.fnameescape(write('x.txt', 'plain text')))
vim.cmd.edit(vim.fn.fnameescape(write('rs/Cargo.lock', '# lock')))
vim.wait(1000)
local after = error_lines()
report(#after == before, 'no_parser_no_error', table.concat(vim.list_slice(after, before + 1), ' | '))

vim.cmd(failed and 'cquit 1' or 'qall!')
