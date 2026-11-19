# Neovim Config Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the kickstart-derived single-file config into a modular, documented config with the plugin set the user chose.

**Architecture:** `init.lua` only sets leader and requires `config.*`. `lua/config/` holds options, keymaps, autocmds and the lazy.nvim bootstrap, which imports `plugins` and `plugins.lang`. Each `lua/plugins/*.lua` returns a list of lazy specs for one area. A headless smoke test (`tests/smoke.lua`) is the regression gate after every task.

**Tech Stack:** Neovim 0.12.6, lazy.nvim, mason, Lua. Formatting: stylua (`.stylua.toml`).

**Spec:** `docs/superpowers/specs/2026-11-19-nvim-config-restructure-design.md`

## Global Constraints

- Neovim 0.12.6. nvim-treesitter on branch `main` (needs tree-sitter CLI ≥ 0.26.1; 0.26.9 installed).
- Code comments: short, English. README: Polish is fine, but keymaps are listed verbatim.
- Every existing keymap stays, except mini.surround: `sa/sd/sr/sf/sF/sh/sn` → `gsa/gsd/gsr/gsf/gsF/gsh/gsn`.
- Removed: supermaven-nvim, csv.vim, yaml.nvim, neo-tree.nvim, nvim-dev-container, fidget.nvim, mini.statusline, `lua/kickstart/`, `lua/custom/`, `doc/`, `.github/`.
- Added: oil.nvim, flash.nvim, trouble.nvim, lazygit.nvim, `dlyongemallo/diffview-plus.nvim`, lualine.nvim, noice.nvim + nvim-notify, render-markdown.nvim, SchemaStore.nvim.
- `stylua --check .` passes after every task (binary: `~/.local/share/nvim/mason/bin/stylua`).
- No commits unless the user asks. "Checkpoint" steps = run the smoke test plus `git status --short`.

## Review Focus

1. **Opening nvim in a directory or with no args.** Oil replaces netrw, so `nvim .` must show oil and not an error. → smoke check `dir_opens_oil`.
2. **A buffer whose filetype has no treesitter parser** (e.g. `Cargo.lock`, a plain `.txt`). The FileType autocmd must not throw. → smoke check `no_parser_no_error`.
3. **Startup with transparent bg and nvim-notify.** nvim-notify warns about `Normal` having no bg unless `background_colour` is set, and noice must not swallow real errors. → smoke check `messages_clean` (no `Error`/`warn` in `:messages` after startup).
4. **Compose files.** A `docker-compose.yml` must get both `yamlls` and `docker_language_server`, and treesitter yaml highlighting, despite the compound filetype. → smoke check on the `compose.yaml` fixture.
5. **Old muscle memory `s`.** In normal mode `s` must be flash (not substitute-char), and `gsa` must add a surround. → smoke keymap checks.

---

### Task 1: Headless smoke test

**Files:**
- Create: `tests/smoke.lua`
- Create: `tests/run.sh`

**Interfaces:**
- Produces: `tests/run.sh` (exit 0 = all pass; prints one `PASS|FAIL <check> <detail>` line per check). All later tasks run it.

- [ ] **Step 1: Write `tests/smoke.lua`**, run via `nvim --headless -c 'luafile tests/smoke.lua'`. It creates a temp dir (`vim.fn.tempname()`) with fixtures, then performs checks with `vim.wait(20000, cond, 200)`, writes results to stdout, and exits with `cq 1` on any FAIL, else `qa!`.

  Fixtures → expected LSP clients (attached to that buffer) and treesitter highlighter active:

  | file | clients | ts |
  |---|---|---|
  | `c/main.c` | clangd | yes |
  | `py/main.py` | pyright, ruff | yes |
  | `go/main.go` + `go/go.mod` (`module x\n\ngo 1.22`) | gopls | yes |
  | `rs/src/main.rs` + `rs/Cargo.toml` (minimal `[package]`) | rust_analyzer | yes |
  | `q.sql` | sqlls | yes |
  | `compose.yaml` | yamlls, docker_language_server | yes |
  | `Dockerfile` | docker_language_server | yes |
  | `x.json` | jsonls | yes |
  | `x.lua` | lua_ls | yes |
  | `README.md` | – | yes |

  Other checks:
  - `messages_clean`: after startup + 2s, `vim.fn.execute('messages')` contains neither `E%d+:` nor `Error` nor `stack traceback`.
  - `plugins_absent`: none of `supermaven-nvim, csv.vim, yaml.nvim, neo-tree.nvim, nvim-dev-container, fidget.nvim` in `require('lazy.core.config').plugins`.
  - `plugins_present`: all of `oil.nvim, flash.nvim, trouble.nvim, lazygit.nvim, diffview-plus.nvim, lualine.nvim, noice.nvim, nvim-notify, render-markdown.nvim, SchemaStore.nvim` present.
  - keymaps (`vim.fn.maparg(lhs, mode, false, true)` non-empty): `n:s`, `x:s`, `n:S`, `n:gsa`, `n:-`, `n:<leader>gg`, `n:<leader>gd`, `n:<leader>gh`, `n:<leader>xx`, `n:<leader>tm`, `n:<leader>sf`, `n:<leader>f`, `n:<C-/>`.
  - `dir_opens_oil`: `:edit <tmpdir>` → `vim.bo.filetype == 'oil'`.
  - `no_parser_no_error`: `:edit x.txt` + `:edit Cargo.lock` produce no new error in `:messages`.

  Note: the leader is space, so use `' gg'`-style lhs strings or `vim.keycode`.

- [ ] **Step 2: Write `tests/run.sh`**: `cd` to the repo root, run the command above with `timeout 180`, propagate the exit code.

- [ ] **Step 3: Run against the current config to get a baseline**

  Run: `bash tests/run.sh`
  Expected: FAIL on plugins_present/absent, new keymaps, oil, compose/Dockerfile clients. PASS on C/Python/Go/Rust/SQL/JSON/Lua clients. Record the baseline in the task notes.

### Task 2: Split into modules (no behavior change)

**Files:**
- Modify: `init.lua` (becomes ~10 lines)
- Create: `lua/config/{options,keymaps,autocmds,lazy}.lua`
- Create: `lua/plugins/{ui,editor,treesitter,lsp,completion,format,lint,git,debug}.lua`, `lua/plugins/lang/{python,go,sql}.lua`
- Delete: `lua/kickstart/`, `lua/custom/`, `doc/`, `.github/`

**Interfaces:**
- Produces: `require('config.lazy')` calls `require('lazy').setup({ { import = 'plugins' }, { import = 'plugins.lang' } }, opts)`. Every plugin file returns a list of specs.

- [ ] **Step 1: Move code verbatim** (minus kickstart tutorial comments, plus the one-line English comment per plugin), mapping as in the spec's "Struktura plików". Contents of `lua/kickstart/plugins/*.lua` go to: debug → `plugins/debug.lua`; gitsigns (merge the two gitsigns specs into one) → `plugins/git.lua`; lint → `plugins/lint.lua`; autopairs → `plugins/editor.lua`; indent_line → `plugins/ui.lua`; neo-tree stays for now in `plugins/editor.lua`. Move the venv auto-activation into the `init` function of the venv-selector spec in `lang/python.lua`. In `config/autocmds.lua`, add a `BufReadPost` autocmd that restores the last cursor position (`'"` mark), skipping `gitcommit`/`gitrebase` and only when the mark is within the buffer.
- [ ] **Step 2: Drop the dead plugins in the same move**: supermaven, csv.vim, yaml.nvim, nvim-dev-container. Remove `<leader>c` from which-key only if nothing else uses it (venv-selector `<leader>cv` does, so keep it).
- [ ] **Step 3: Verify**: `stylua --check .` passes and `bash tests/run.sh` gives the Task 1 baseline, except `plugins_absent` now shows only neo-tree and fidget as still present.

### Task 3: Treesitter on `main`

**Files:**
- Modify: `lua/plugins/treesitter.lua`

- [ ] **Step 1: Spec**: `{ 'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false, build = ':TSUpdate' }`. Its config:
  - calls `require('nvim-treesitter').install(parsers)` with `parsers = { 'bash','c','cpp','diff','dockerfile','go','gomod','gosum','html','json','lua','luadoc','markdown','markdown_inline','python','query','rust','sql','toml','vim','vimdoc','yaml','gitcommit','git_rebase' }`;
  - calls `vim.treesitter.language.register('yaml', 'yaml.docker-compose')`;
  - creates a `FileType` autocmd (group `user-treesitter`) that resolves `lang = vim.treesitter.language.get_lang(ft)` and runs `pcall(vim.treesitter.start, buf, lang)`; if the start succeeded and the ft is not `c`/`cpp`, it sets `vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
- [ ] **Step 2: treesitter-context spec unchanged** (separate spec, already fixed).
- [ ] **Step 3: Remove the old parser install dir conflict**: `:Lazy sync` handles the branch switch. Verify with `nvim --headless "+Lazy! sync" +qa`, then `bash tests/run.sh`: all `ts` columns PASS, and `no_parser_no_error` PASS.

### Task 4: LSP, lint, format updates

**Files:**
- Modify: `lua/plugins/lsp.lua`, `lua/plugins/lint.lua`, `lua/plugins/completion.lua`, `lua/config/autocmds.lua`

- [ ] **Step 1: Servers** (in the `servers` table):
  - `jsonls`: `settings.json = { schemas = require('schemastore').json.schemas(), validate = { enable = true } }`;
  - `yamlls`: `settings.yaml = { schemaStore = { enable = false, url = '' }, schemas = require('schemastore').yaml.schemas() }`;
  - `pyright`: `settings.pyright.disableOrganizeImports = true`;
  - `ruff = {}`;
  - `rust_analyzer`: `settings['rust-analyzer'].check.command = 'clippy'`;
  - `docker_language_server = {}`.

  Add `b0o/SchemaStore.nvim` (`lazy = true`) to the lspconfig dependencies. In the LspAttach callback: if `client.name == 'ruff'`, set `client.server_capabilities.hoverProvider = false`. Remove the identity `format` function from `virtual_text`. Remove `fidget.nvim`.
- [ ] **Step 2: Filetype**: in `config/autocmds.lua`, `vim.filetype.add { filename = { ['docker-compose.yml']=…, ['docker-compose.yaml']=…, ['compose.yml']=…, ['compose.yaml']=… } }`, all mapped to `'yaml.docker-compose'`.
- [ ] **Step 3: Mason tools**: add `hadolint` and `markdownlint` to the tool-installer list. Lint: `dockerfile = { 'hadolint' }` next to markdown.
- [ ] **Step 4: blink**: set `fuzzy = { implementation = 'prefer_rust_with_warning' }`.
- [ ] **Step 5: Verify**: `bash tests/run.sh`; all client rows PASS, including compose/Dockerfile. Run `:checkhealth vim.lsp` headless and grep for `ERROR` (expect none).

### Task 5: Editor additions (oil, flash, trouble)

**Files:**
- Modify: `lua/plugins/editor.lua`, `lua/plugins/ui.lua` (which-key groups), `lua/config/lazy.lua`

- [ ] **Step 1: oil**:
  - spec: `stevearc/oil.nvim`, `lazy = false`;
  - opts: `{ default_file_explorer = true, view_options = { show_hidden = true }, skip_confirm_for_simple_edits = false }`;
  - keys: `{ '-', '<cmd>Oil<cr>', desc = 'Open parent directory' }`;
  - remove neo-tree and its `\` map;
  - add `netrwPlugin` to lazy's `performance.rtp.disabled_plugins`, together with `gzip, tarPlugin, tohtml, tutor, zipPlugin`;
  - set `change_detection = { notify = false }`.
- [ ] **Step 2: flash**: `folke/flash.nvim`, `event = 'VeryLazy'`. Keys:
  - `s` (n/x/o) → `require('flash').jump()`;
  - `S` (n/x/o) → `.treesitter()`;
  - `r` (o) → `.remote()`;
  - `<c-s>` (c) → `.toggle()`.

  mini.surround setup gets `mappings = { add='gsa', delete='gsd', find='gsf', find_left='gsF', highlight='gsh', replace='gsr', update_n_lines='gsn' }`. Add which-key group `gs` = 'Surround'.
- [ ] **Step 3: trouble**: `folke/trouble.nvim`, `cmd = 'Trouble'`, `opts = {}`. Keys:
  - `<leader>xx` → `Trouble diagnostics toggle`;
  - `<leader>xX` → `Trouble diagnostics toggle filter.buf=0`;
  - `<leader>xs` → `Trouble symbols toggle`;
  - `<leader>xl` → `Trouble lsp toggle`;
  - `<leader>xq` → `Trouble qflist toggle`.

  Add which-key group `<leader>x` = 'Trouble'.
- [ ] **Step 4: Verify**: `bash tests/run.sh`; the keymap rows for `s`, `S`, `gsa`, `-`, `<leader>xx` PASS, `dir_opens_oil` PASS, and neo-tree no longer appears in `plugins_absent`.

### Task 6: Git (lazygit, diffview)

**Files:**
- Modify: `lua/plugins/git.lua`, `lua/plugins/ui.lua`

- [ ] **Step 1: lazygit**: `kdheepak/lazygit.nvim`, `cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitLog' }`, depends on plenary. Key: `<leader>gg` → `<cmd>LazyGit<cr>`.
- [ ] **Step 2: diffview**: `dlyongemallo/diffview-plus.nvim`, `cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' }`. Keys:
  - `<leader>gd` → `DiffviewOpen`;
  - `<leader>gh` → `DiffviewFileHistory %`;
  - `<leader>gH` → `DiffviewFileHistory`;
  - `<leader>gq` → `DiffviewClose`.

  Add which-key group `<leader>g` = '[G]it'.
- [ ] **Step 3: Verify**: `bash tests/run.sh`, `<leader>gg/gd/gh` PASS. If the `lazygit` binary is missing, the smoke test only checks the mapping (installing the binary is on the user).

### Task 7: UI (lualine, noice, render-markdown)

**Files:**
- Modify: `lua/plugins/ui.lua`, `lua/plugins/editor.lua` (remove mini.statusline)
- Create: `lua/plugins/lang/markdown.lua`

- [ ] **Step 1: lualine**: `nvim-lualine/lualine.nvim`, `event = 'VeryLazy'`, `options.theme = 'tokyonight'`, `globalstatus = true`. Sections:
  - a = mode;
  - b = branch, diff, diagnostics;
  - c = filename (path = 1);
  - x = venv (component: `function() local ok, vs = pcall(require, 'venv-selector'); local v = ok and vs.venv() ; return v and ('🐍 ' .. vim.fn.fnamemodify(v, ':h:t')) or '' end`; fall back to `vim.env.VIRTUAL_ENV` when venv-selector is not loaded), LSP client names of the current buffer, filetype;
  - y = progress;
  - z = location.

  Remove the `mini.statusline` setup.
- [ ] **Step 2: noice**: `folke/noice.nvim`, `event = 'VeryLazy'`, deps `MunifTanjim/nui.nvim` and `rcarriga/nvim-notify` (opts `{ background_colour = '#000000' }`).
  - opts: `lsp.override` for `vim.lsp.util.convert_input_to_markdown_lines`, `vim.lsp.util.stylize_markdown` = true; `lsp.signature.enabled = false` (blink does signatures); `lsp.progress.enabled = true`;
  - presets: `bottom_search = true, command_palette = true, long_message_to_split = true, lsp_doc_border = true`.
- [ ] **Step 3: render-markdown**: `MeanderingProgrammer/render-markdown.nvim`, `ft = 'markdown'`, `opts = {}`. Key: `<leader>tm` → `<cmd>RenderMarkdown toggle<cr>`. (`<leader>t` group exists.)
- [ ] **Step 4: Verify**: `bash tests/run.sh`; ALL checks PASS, including `messages_clean` (watch the nvim-notify bg warning) and `<leader>tm`.

### Task 8: Docs, lockfile, final verification

**Files:**
- Rewrite: `README.md` (Polish: what's in the config, requirements (`lazygit`, `tree-sitter`, `rg`, `fd`, `make`, `cc`, `node`, `go`, `cargo`, `uv`), how to run `tests/run.sh`, and a keymap cheat-sheet table grouped by area, generated from the actual mappings)
- Modify: `.gitignore` (remove `lazy-lock.json`)

- [ ] **Step 1: README** with every custom mapping from `lua/config/keymaps.lua` and all plugin `keys`. Cross-check against `nvim --headless -c 'lua for _,m in ipairs(vim.api.nvim_get_keymap("n")) do if m.desc then print(m.lhs, m.desc) end end' -c qa`.
- [ ] **Step 2: Un-ignore the lockfile**, then `nvim --headless "+Lazy! sync" +qa` (removes plugins that are no longer used: `Lazy! clean` is part of sync).
- [ ] **Step 3: Final**: `stylua --check .`, `bash tests/run.sh` all PASS, `nvim --headless "+checkhealth" "+w! /tmp/…/health.txt" +qa`, then grep `ERROR` and report anything new versus before.
- [ ] **Step 4: Checkpoint**: show `git status --short` and ask the user whether to commit (and on which branch).
