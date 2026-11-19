#!/usr/bin/env bash
# Smoke test for the Neovim config: installs missing plugins/tools, then runs tests/smoke.lua headless.
# Usage: bash tests/run.sh
set -u
cd "$(dirname "$0")/.."

# Install anything missing so the checks don't race background installs.
timeout 900 nvim --headless -c 'luafile tests/prepare.lua' >/dev/null 2>&1

timeout 300 nvim --headless -c 'luafile tests/smoke.lua' 2>&1 | tr '\r' '\n' | grep -E '^(PASS|FAIL) '
status=${PIPESTATUS[0]}

# `nvim <dir>` must open oil at startup (netrw is disabled).
ft=$(timeout 60 nvim --headless "$PWD" -c 'lua vim.defer_fn(function() io.stdout:write("FT=" .. vim.bo.filetype .. "\n"); vim.cmd("qa!") end, 1500)' 2>&1 | tr '\r' '\n' | sed -n 's/^FT=//p')
if [ "$ft" = oil ]; then echo "PASS startup_dir_opens_oil"; else echo "FAIL startup_dir_opens_oil ft=$ft"; status=1; fi

exit "$status"
