-- Language servers: installation (mason), per-server settings, keymaps, diagnostics.
return {
  { -- Lua LSP knows about the Neovim API and plugins
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} }, -- must load before its dependents
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local builtin = require 'telescope.builtin'
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', builtin.lsp_references, '[G]oto [R]eferences')
          map('gri', builtin.lsp_implementations, '[G]oto [I]mplementation')
          map('grd', builtin.lsp_definitions, '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('grt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition')
          map('gO', builtin.lsp_document_symbols, 'Open Document Symbols')
          map('gW', builtin.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          -- Highlight references of the symbol under the cursor after `updatetime`.
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local hl_group = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = { source = 'if_many', spacing = 2 },
      }

      -- Per-server overrides, merged on top of nvim-lspconfig's defaults (lsp/<name>.lua).
      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--function-arg-placeholders=false',
            '--fallback-style={BasedOnStyle: LLVM, IndentWidth: 4}',
          },
          init_options = {
            usePlaceholders = false,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          -- no snippet completions: avoids placeholder junk like `init-statement`
          capabilities = { textDocument = { completion = { completionItem = { snippetSupport = false } } } },
        },
        gopls = {},
        pyright = {},
        rust_analyzer = {},
        jsonls = {},
        yamlls = {},
        sqlls = {},
        lua_ls = {
          settings = { Lua = { completion = { callSnippet = 'Replace' } } },
        },
      }

      -- Mason installs the servers above plus these tools (formatters, linters, debuggers).
      local ensure_installed = vim.tbl_keys(servers)
      vim.list_extend(ensure_installed, {
        'stylua',
        'clang-format',
        'ruff',
        'prettier',
        'sql-formatter',
        'goimports',
        'debugpy',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      -- mason-lspconfig v2 calls vim.lsp.enable() for every installed server.
      require('mason-lspconfig').setup {
        ensure_installed = {}, -- installation is handled by mason-tool-installer
        automatic_enable = true,
      }
    end,
  },
}
