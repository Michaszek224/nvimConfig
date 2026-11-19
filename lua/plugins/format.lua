-- Formatting on save and on <leader>f.
return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = {
        timeout_ms = 1000, -- node-based formatters can take >500 ms to start
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        python = { 'ruff_fix', 'ruff_format' }, -- autofixes first, then formatting
        go = { 'goimports' }, -- gofmt + import cleanup
        rust = { 'rustfmt' }, -- from rustup, not mason
        sql = { 'sql-formatter' },
        html = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
      },
      formatters = {
        ['clang-format'] = {
          prepend_args = {
            '-style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, AllowShortFunctionsOnASingleLine: None, BreakBeforeBraces: Allman}',
          },
        },
      },
    },
  },
}
