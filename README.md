# Konfiguracja Neovim

Modułowa konfiguracja Neovim (0.12+) na [lazy.nvim](https://github.com/folke/lazy.nvim),
wyrosła z kickstart.nvim. Języki: **Python, Go, Rust, C/C++**, do tego **SQL**,
**Docker** i **YAML/JSON**. Leader = `spacja`.

## Struktura

```
init.lua                    leader + ładowanie lua/config/*
lua/config/options.lua      opcje edytora
lua/config/keymaps.lua      globalne skróty (bez pluginów)
lua/config/autocmds.lua     autocmd + wykrywanie filetype (compose)
lua/config/lazy.lua         bootstrap lazy.nvim, import lua/plugins/ i lua/plugins/lang/
lua/plugins/ui.lua          tokyonight, lualine, noice, which-key, todo-comments, linie wcięć
lua/plugins/editor.lua      telescope, oil, flash, trouble, mini.ai/surround, autopairs, toggleterm
lua/plugins/treesitter.lua  nvim-treesitter (gałąź main) + treesitter-context
lua/plugins/lsp.lua         mason, serwery LSP i ich ustawienia, diagnostyka, skróty LSP
lua/plugins/completion.lua  blink.cmp + LuaSnip
lua/plugins/format.lua      conform (formatowanie przy zapisie)
lua/plugins/lint.lua        nvim-lint (markdownlint, hadolint)
lua/plugins/git.lua         gitsigns, lazygit, diffview
lua/plugins/debug.lua       nvim-dap + dap-ui
lua/plugins/lang/*.lua      python (venv), go (go.nvim), sql (dadbod), markdown (render)
tests/                      test dymny (patrz niżej)
```

Nowy plugin = nowy spec w odpowiednim pliku w `lua/plugins/` (lazy wczyta go sam).
Nowy serwer LSP = wpis w tabeli `servers` w `lua/plugins/lsp.lua` (mason zainstaluje go sam).

## Wymagania

`git`, `make`, `cc`, `rg` (ripgrep), `fd`, `node`/`npm` (serwery LSP i prettier),
`tree-sitter` CLI ≥ 0.26.1 (parsery), `go`, `cargo`/`rustup` (+ `rustfmt`), `uv`,
czcionka Nerd Font, **`lazygit`** (`sudo pacman -S lazygit`).
Serwery LSP, formattery, lintery i debuggery instaluje mason automatycznie.

## Języki

| Język | LSP | Formatowanie | Lint | Debug |
|---|---|---|---|---|
| Python | pyright (typy, hover) + ruff (lint, importy) | ruff | ruff | debugpy |
| Go | gopls (+ go.nvim: `:GoTest`, `:GoFillStruct`, `:GoIfErr`…) | goimports | gopls | delve |
| Rust | rust-analyzer (sprawdzanie clippy) | rustfmt | clippy | codelldb |
| C/C++ | clangd (+ clang-tidy) | clang-format (Allman, 4 spacje) | clang-tidy | codelldb |
| SQL | sqlls + podpowiedzi z bazy (dadbod) | sql-formatter | – | – |
| Docker | docker-language-server (Dockerfile + compose) | – | hadolint | – |
| JSON/YAML | jsonls / yamlls ze schematami SchemaStore | prettier | schematy | – |
| Markdown | – | prettier | markdownlint | – |

Python: przy starcie aktywuje się `./.venv` z katalogu, w którym uruchomiono nvim
(projekty uv). Inny venv wybierzesz przez `<leader>cv`.

## Skróty

### Ogólne

| Skrót | Akcja |
|---|---|
| `<Esc>` | wyczyść podświetlenie wyszukiwania |
| `<C-h/j/k/l>` | przejdź do okna w lewo/dół/górę/prawo |
| `<C-/>` | pływający terminal (w terminalu też zamyka) |
| `<Esc><Esc>` | wyjście z trybu terminala |
| `-` | **oil**: katalog bieżącego pliku jako bufor (edytujesz → `:w` zapisuje zmiany na dysku) |
| `s` + 2 znaki + etykieta | **flash**: skok w dowolne widoczne miejsce |
| `S` | flash: zaznacz węzeł treesittera (funkcję, blok…) |
| `r` (po operatorze, np. `yr`) | flash remote: operacja w innym miejscu bez przesuwania kursora |
| `<C-s>` (w `/` lub `?`) | włącz/wyłącz flash w wyszukiwaniu |
| `<leader>f` | formatuj bufor |
| `<leader>q` | diagnostyka do listy lokalizacji |

### Szukanie (telescope)

| Skrót | Akcja |
|---|---|
| `<leader>sf` | pliki |
| `<leader>sg` | grep w projekcie |
| `<leader>sw` | słowo pod kursorem |
| `<leader><leader>` | otwarte bufory |
| `<leader>/` | szukaj w bieżącym buforze |
| `<leader>s/` | grep w otwartych plikach |
| `<leader>s.` | ostatnio otwierane pliki |
| `<leader>sd` | diagnostyka |
| `<leader>sr` | wznów ostatnie wyszukiwanie |
| `<leader>sh` / `sk` / `ss` | pomoc / skróty / wszystkie pickery |
| `<leader>sn` | pliki tej konfiguracji |

### LSP (w buforze z serwerem)

| Skrót | Akcja |
|---|---|
| `grd` / `grD` | definicja / deklaracja |
| `grr` | referencje |
| `gri` | implementacje |
| `grt` | definicja typu |
| `grn` | zmień nazwę |
| `gra` | code action |
| `gO` / `gW` | symbole w pliku / w projekcie |
| `K` | dokumentacja (hover) |
| `[d` / `]d` | poprzedni / następny błąd |
| `<C-w>d` | pokaż diagnostykę pod kursorem |
| `<leader>th` | włącz/wyłącz inlay hints |

### Lista błędów (trouble)

| Skrót | Akcja |
|---|---|
| `<leader>xx` | diagnostyka całego projektu |
| `<leader>xX` | diagnostyka bieżącego bufora |
| `<leader>xs` | symbole |
| `<leader>xl` | definicje/referencje LSP |
| `<leader>xq` | quickfix |

### Uzupełnianie (blink.cmp)

| Skrót | Akcja |
|---|---|
| `<Tab>` | wybierz i zaakceptuj podpowiedź |
| `<C-y>` | zaakceptuj |
| `<C-n>` / `<C-p>` | następna / poprzednia |
| `<C-space>` | pokaż menu / dokumentację |
| `<C-e>` | zamknij menu |
| `<C-k>` | podpowiedź sygnatury |

### Edycja tekstu (mini.nvim)

| Skrót | Akcja |
|---|---|
| `gsa{ruch}{znak}` | dodaj otoczenie, np. `gsaiw)` → `(słowo)` |
| `gsd{znak}` | usuń otoczenie, np. `gsd'` |
| `gsr{stary}{nowy}` | zamień otoczenie, np. `gsr)'` |
| `gsf` / `gsF` / `gsh` | znajdź otoczenie w prawo / w lewo / podświetl |
| `va)` / `yinq` / `ci'` | obiekty tekstowe mini.ai (around/inside, next/last) |
| `gc{ruch}` / `gcc` | zakomentuj (wbudowane) |

### Git

| Skrót | Akcja |
|---|---|
| `<leader>gg` | lazygit (pełny interfejs gita) |
| `<leader>gd` | diffview: zmiany w drzewie roboczym |
| `<leader>gh` | historia bieżącego pliku |
| `<leader>gH` | historia repozytorium |
| `<leader>gq` | zamknij diffview |
| `]c` / `[c` | następna / poprzednia zmiana (hunk) |
| `<leader>hs` | stage/unstage hunka (w trybie visual: zaznaczenia) |
| `<leader>hr` | cofnij hunk |
| `<leader>hS` / `hR` | stage / cofnij cały plik |
| `<leader>hp` | podgląd hunka |
| `<leader>hb` | blame linii |
| `<leader>hd` / `hD` | diff względem indeksu / ostatniego commita |
| `<leader>tb` | blame przy bieżącej linii (przełącz) |
| `<leader>tD` | pokaż usunięte linie inline |

### Debugowanie (DAP)

| Skrót | Akcja |
|---|---|
| `<F5>` | start / kontynuuj |
| `<F1>` / `<F2>` / `<F3>` | step into / over / out |
| `<leader>b` | breakpoint |
| `<leader>B` | breakpoint warunkowy |
| `<F7>` | pokaż/ukryj dap-ui |

### Inne

| Skrót | Akcja |
|---|---|
| `<leader>cv` | wybierz virtualenv Pythona |
| `<leader>db` | interfejs baz danych (DBUI) |
| `<leader>tm` | włącz/wyłącz renderowanie markdown |

Pełną, aktualną listę pokaże `<leader>sk`, a which-key podpowiada po wciśnięciu `<leader>`.

## Test

```sh
bash tests/run.sh
```

Doinstalowuje brakujące pluginy, narzędzia masona i parsery, potem uruchamia nvim
bez interfejsu na przykładowych plikach każdego języka. Sprawdza, czy podłączają się
właściwe serwery LSP, działa treesitter, istnieją skróty, a start nie zgłasza błędów.
Warto puścić po `:Lazy update`. Kod wyjścia 0 = wszystko działa.

`lazy-lock.json` jest w repo: po nieudanej aktualizacji pluginów `:Lazy restore`
wraca do wersji z commita.
