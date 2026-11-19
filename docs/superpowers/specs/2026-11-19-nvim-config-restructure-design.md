# Przebudowa konfiguracji Neovim — projekt

Data: 2026-11-19 · Neovim 0.12.6 · Arch Linux

## Cel

Konfiguracja wyrosła z kickstart.nvim: jeden `init.lua` (~1100 linii, w większości
komentarze kickstarta), pluginy dodawane ad hoc, część nieużywana. Cel: **porządna,
modułowa konfiguracja**, w której wiadomo, co jest zainstalowane i po co, z pełnym
wsparciem dla faktycznie używanych języków i bez martwego balastu.

## Cele / nie-cele / anty-cele

- **Cele:** pełne wsparcie (LSP, format, lint, debug) dla Python, Go, Rust, C/C++;
  SQL (dadbod), Dockerfile/compose, YAML/JSON ze schematami; git (lazygit, diffview);
  nawigacja (oil, flash, trouble); ładniejszy UI (lualine, noice); podgląd markdown.
- **Nie-cele:** AI w edytorze; web (JS/TS); testy w edytorze (neotest); harpoon,
  sesje, dashboard, bufferline; rustaceanvim; zmiana pickera (zostaje telescope).
- **Anty-cele:** zmiana skrótów, do których użytkownik jest przyzwyczajony (poza
  koniecznymi kolizjami, opisanymi niżej); konfiguracja, której nie da się
  zrozumieć czytając pliki (dlatego nie LazyVim).

## Podejścia (wybrane: A)

- **A. Moduły wg obszaru** ✅ — `init.lua` ~10 linii, `lua/config/*` (opcje, skróty,
  autocmd, bootstrap lazy), `lua/plugins/*.lua` po jednym pliku na obszar.
  Dodanie/usunięcie pluginu = jeden plik. Wybrane przez użytkownika.
- B. Jeden wyczyszczony plik (~600 linii) — prościej, ale trudniej nawigować.
- C. LazyVim — mało własnego kodu, ale „magia”, trudniej zrozumieć i debugować.

## Decyzje użytkownika

| Obszar | Decyzja |
|---|---|
| Języki | Python, Go, Rust, C/C++ |
| Inne | SQL/bazy, Docker, YAML/JSON |
| Zostają z „egzotycznych” | toggleterm |
| Usuwane | supermaven, csv.vim, yaml.nvim, neo-tree, nvim-dev-container (zarchiwizowany) |
| Pliki | oil.nvim (zastępuje neo-tree) |
| Git | + lazygit, + diffview |
| Wygoda | + flash.nvim, + trouble.nvim |
| Języki+ | + render-markdown.nvim |
| UI | + lualine (zamiast mini.statusline), + noice.nvim |
| AI | brak |
| Struktura | moduły wg obszaru |
| Komentarze | krótkie, po angielsku; spis skrótów w README |

## Struktura plików

```
init.lua                      -- leader + require config.*
lua/config/options.lua        -- vim.o / vim.opt
lua/config/keymaps.lua        -- globalne skróty (nie-pluginowe)
lua/config/autocmds.lua       -- yank highlight, przywracanie kursora, …
lua/config/lazy.lua           -- bootstrap lazy.nvim + setup({ import = 'plugins' }, { import = 'plugins.lang' })
lua/plugins/ui.lua            -- tokyonight, lualine, noice(+notify), which-key, indent-blankline, todo-comments
lua/plugins/editor.lua        -- telescope, oil, flash, trouble, mini.ai/surround, autopairs, guess-indent, toggleterm
lua/plugins/treesitter.lua    -- nvim-treesitter (gałąź main) + context
lua/plugins/lsp.lua           -- lspconfig, mason, mason-tool-installer, lazydev, SchemaStore, definicje serwerów, diagnostyka
lua/plugins/completion.lua    -- blink.cmp + LuaSnip + friendly-snippets
lua/plugins/format.lua        -- conform
lua/plugins/lint.lua          -- nvim-lint
lua/plugins/git.lua           -- gitsigns, lazygit, diffview
lua/plugins/debug.lua         -- nvim-dap, dap-ui, mason-nvim-dap, dap-go
lua/plugins/lang/python.lua   -- venv-selector + auto-aktywacja .venv (w `init`)
lua/plugins/lang/go.lua       -- go.nvim
lua/plugins/lang/sql.lua      -- vim-dadbod, dbui, completion
lua/plugins/lang/markdown.lua -- render-markdown
README.md                     -- opis + pełna ściąga skrótów
```

Usuwane pozostałości kickstarta: `lua/kickstart/`, `lua/custom/`, `doc/kickstart.txt`,
`doc/tags`, `.github/` (szablony issue/PR i workflow repo kickstarta).
`LICENSE.md` zostaje (MIT kickstarta wymaga zachowania noty). `.stylua.toml` zostaje.

## Ustalenia techniczne (calls Claude'a — do korekty)

- **Treesitter → gałąź `main`**: `master` jest zamrożony. `main` wymaga nvim 0.12 i
  `tree-sitter` CLI ≥ 0.26.1 (jest 0.26.9). Highlight przez `vim.treesitter.start()`
  w autocmd `FileType`, indent przez `nvim-treesitter.indentexpr()` (poza C/C++ —
  tam `cindent`), parsery instalowane `require('nvim-treesitter').install{…}`.
- **Kolizja flash ↔ mini.surround**: flash na `s` (skok) i `S` (treesitter select);
  surround przeniesiony na `gsa` / `gsd` / `gsr` / `gsf` / `gsh`.
- **diffview**: fork `dlyongemallo/diffview-plus.nvim` (oryginał bez commitów od 2024-08).
- **lazygit**: plugin `kdheepak/lazygit.nvim`; binarkę `lazygit` użytkownik instaluje
  `sudo pacman -S lazygit` (nie ma jej w systemie).
- **noice** przejmuje komunikaty i postęp LSP → **fidget usunięty** (duplikat).
  `noice.lsp.signature` wyłączone (robi to blink). `nvim-notify` z
  `background_colour` ustawionym (wymagane przy przezroczystym tle).
- **oil**: `default_file_explorer = true` (zastępuje netrw), `-` = katalog nadrzędny.
- **Python**: pyright + ruff (LSP); ruff `hoverProvider = false` (hover robi pyright),
  pyright `disableOrganizeImports = true` (robi ruff). Auto-aktywacja `.venv`
  zachowana, przeniesiona do `init` speca venv-selectora.
- **Rust**: `rust_analyzer` z `check.command = 'clippy'`; rustfmt z rustup.
- **C/C++**: clangd i clang-format bez zmian (styl Allman wymuszony, jak było).
- **Docker**: LSP `docker_language_server` (oficjalny od Dockera: Dockerfile + compose
  w jednym serwerze), lint `hadolint`. Pliki `docker-compose.y(a)ml` / `compose.y(a)ml`
  dostają filetype `yaml.docker-compose` (nvim domyślnie daje `yaml`), z parserem
  treesittera `yaml`; yamlls obsługuje ten filetype również.
- **YAML/JSON**: SchemaStore.nvim dla `jsonls` i `yamlls`.
- **blink.cmp**: `fuzzy = 'prefer_rust_with_warning'`; reszta jak teraz (Tab akceptuje).
- **lualine**: tryb, branch, diff, diagnostyki, plik | aktywny venv, LSP, filetype, pozycja.
- **Diagnostyka**: usunięty no-op `format` w `virtual_text`.
- **lazy.nvim**: `change_detection.notify = false`, wyłączone zbędne wbudowane pluginy
  (gzip, tar, zip, tohtml, tutor, netrw). `lazy-lock.json` **commitowany**
  (usunięty z `.gitignore`).
- **Nowe skróty**: `<leader>gg` lazygit, `<leader>gd`/`<leader>gh` diffview / historia
  pliku, `<leader>x…` trouble, `s`/`S` flash, `-` oil, `<leader>tm` render-markdown.
  Wszystkie dotychczasowe skróty zostają.

## Weryfikacja

Headless nvim: start bez błędów w `:messages`; dla `.c/.py/.go/.rs/.sql/.yaml/Dockerfile`
— właściwe klienty LSP i aktywny treesitter highlight; `stylua --check .`;
`:checkhealth` bez nowych błędów.

## Pozostawione wykonawcy

Dokładne opcje kolorów/sekcji lualine, kolejność wpisów w which-key, treść README.
