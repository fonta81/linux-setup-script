#!/usr/bin/env bash
# ==============================================================================
# common.sh — Cargador de funciones compartidas para los instaladores.
# No se ejecuta solo: cada script de distro hace `source lib/common.sh`.
# ==============================================================================

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core/core.sh" || return 1
source "$LIB_DIR/core/ui.sh" || return 1
source "$LIB_DIR/tools/update.sh" || return 1
source "$LIB_DIR/tools/brew.sh" || return 1
source "$LIB_DIR/tools/flatpak.sh" || return 1
source "$LIB_DIR/tools/zsh.sh" || return 1
source "$LIB_DIR/tools/yazi.sh" || return 1
source "$LIB_DIR/tools/neovim.sh" || return 1
source "$LIB_DIR/tools/lazygit.sh" || return 1
source "$LIB_DIR/tools/pokemon.sh" || return 1
source "$LIB_DIR/tools/node.sh" || return 1
source "$LIB_DIR/tools/gemini.sh" || return 1
source "$LIB_DIR/tools/copilot.sh" || return 1
source "$LIB_DIR/tools/repomix.sh" || return 1
source "$LIB_DIR/tools/lazyssh.sh" || return 1
source "$LIB_DIR/tools/lavat.sh" || return 1
source "$LIB_DIR/tools/brave.sh" || return 1
source "$LIB_DIR/tools/spotify.sh" || return 1
source "$LIB_DIR/tools/obsidian.sh" || return 1
source "$LIB_DIR/tools/dank.sh" || return 1
source "$LIB_DIR/tools/antigravity.sh" || return 1
source "$LIB_DIR/tools/opencode.sh" || return 1
source "$LIB_DIR/tools/configs.sh" || return 1
source "$LIB_DIR/tools/plugins.sh" || return 1
source "$LIB_DIR/tools/zshrc.sh" || return 1

detect_distro
