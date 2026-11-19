-- Python: virtualenv handling. LSP (pyright, ruff) lives in plugins/lsp.lua.
return {
  {
    'linux-cultist/venv-selector.nvim',
    dependencies = { 'neovim/nvim-lspconfig', 'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap-python' },
    init = function()
      -- Auto-activate ./.venv (uv projects) at startup, before any LSP starts,
      -- so pyright, debugpy and :terminal all see the project interpreter.
      -- python3_host_prog is left alone: the provider needs pynvim, which project venvs lack.
      local venv = vim.fn.getcwd() .. '/.venv'
      if vim.fn.executable(venv .. '/bin/python') == 1 then
        vim.env.VIRTUAL_ENV = venv
        vim.env.PATH = venv .. '/bin:' .. vim.env.PATH
        vim.api.nvim_create_autocmd('VimEnter', {
          once = true,
          callback = function()
            vim.defer_fn(function()
              vim.notify('🐍 Virtual environment: ' .. vim.fn.fnamemodify(venv, ':h:t') .. '/.venv')
            end, 500)
          end,
        })
      end
    end,
    opts = {
      settings = {
        options = {
          enable_cached_venvs = true, -- remember the venv picked per project
          notify_user_on_venv_activation = true,
        },
        search = {
          cwd = { command = 'fd python$ .venv/bin' },
        },
      },
    },
    keys = {
      { '<leader>cv', '<cmd>VenvSelect<cr>', desc = 'Select [V]irtualEnv' },
    },
  },
}
