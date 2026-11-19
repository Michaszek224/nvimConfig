#!/usr/bin/env bash
# Smoke test for the Neovim config: installs missing plugins/tools, then runs tests/smoke.lua headless.
# Usage: bash tests/run.sh
set -u
cd "$(dirname "$0")/.."

# Install anything missing so the checks don't race background installs.
timeout 600 nvim --headless '+Lazy! install' '+MasonToolsInstallSync' '+qa' >/dev/null 2>&1

timeout 300 nvim --headless -c 'luafile tests/smoke.lua' 2>&1 | tr '\r' '\n' | grep -E '^(PASS|FAIL) '
exit "${PIPESTATUS[0]}"
