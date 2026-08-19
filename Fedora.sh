#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Script de Auto-Instalación de Herramientas para Fedora
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_root_and_detect_user "$@"

info "Comprobando e instalando requisitos básicos (git, curl, util-linux-user)..."
if ! dnf install -y git curl util-linux-user >/dev/null 2>&1; then
  warn "No se pudieron instalar todos los prerrequisitos iniciales. El script intentará continuar."
fi

# ------------------------------------------------------------------------------
# Registro de herramientas: id | etiqueta | función instalar | función chequear
# ------------------------------------------------------------------------------
register_tool update   "Actualización de Sistema"    install_update            check_update
register_tool flatpak  "Repositorio Flathub"         install_flatpak           check_flatpak
register_tool zsh      "Zsh & Oh My Zsh"             install_zsh_ohmyzsh       check_zsh
register_tool yazi     "Yazi File Manager"           install_yazi              check_yazi
register_tool neovim   "Neovim & LazyVim"            install_neovim_lazyvim    check_neovim
register_tool lazygit  "Lazygit"                     install_lazygit           check_lazygit
register_tool pokemon  "Pokemon Colorscripts"        install_pokemon_colorscripts check_pokemon
register_tool gemini   "Gemini Copilot (cli)"        install_gemini_copilot   check_gemini
register_tool brave    "Brave Browser"               install_brave             check_brave
register_tool spotify  "Spotify (Flatpak)"           install_spotify           check_spotify
register_tool obsidian "Obsidian (Flatpak)"          install_obsidian          check_obsidian
register_tool dank     "Dank Material Shell"         install_dank_shell        check_dank
register_tool antigravity "Antigravity CLI"          install_antigravity       check_antigravity
register_tool configs  "Configs Niri"                install_configs           check_configs
register_tool plugins  "Plugins Zsh"                 install_zsh_plugins       check_plugins
register_tool zshrc    "Configuración .zshrc"        configure_zshrc           check_zshrc

main_menu "AUTOINSTALADOR DE HERRAMIENTAS - FEDORA"
