-- Syntax trees: highlighting, indentation, sticky context header.
-- nvim-treesitter `main` branch: it only installs parsers/queries; highlighting is
-- started by Neovim itself (vim.treesitter.start) from the FileType autocmd below.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- main branch does not support lazy-loading
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'diff',
        'dockerfile',
        'git_rebase',
        'gitcommit',
        'go',
        'gomod',
        'gosum',
        'html',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'rust',
        'sql',
        'toml',
        'vim',
        'vimdoc',
        'yaml',
      },
    },
    config = function(_, opts)
      require('nvim-treesitter').install(opts.ensure_installed) -- async, no-op when installed

      -- docker compose files get a compound filetype (see config/autocmds.lua)
      vim.treesitter.language.register('yaml', 'yaml.docker-compose')

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('user-treesitter', { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(event.match)
          if not lang or not pcall(vim.treesitter.start, event.buf, lang) then
            return -- no parser for this filetype
          end
          if event.match ~= 'c' and event.match ~= 'cpp' then -- C/C++ keep cindent
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  { -- Shows the enclosing function/class at the top of the window
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPre',
    opts = {
      max_lines = 3,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = '-',
    },
  },
}
