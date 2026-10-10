#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Script de Auto-Instalación de Herramientas para CachyOS (Arch Linux)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || {
  echo "[ERROR] No se pudo cargar $SCRIPT_DIR/lib/common.sh. Abortando." >&2
  exit 1
}

require_root_and_detect_user "$@"

if [ "${DISTRO:-unknown}" != "cachyos" ]; then
  error "Este instalador es para CachyOS (detectado: ${DISTRO:-desconocido}). Usa Fedora.sh en Fedora."
  exit 1
fi

info "Comprobando requisitos básicos (git, curl)..."
# -Syu y no -Sy a secas: en Arch un -Sy sin -u deja un partial upgrade
# (paquetes nuevos contra librerías viejas) si la máquina iba desactualizada.
prereq_log=$(mktemp /tmp/linux-setup-prereq.XXXXXX.log 2>/dev/null) || prereq_log="/tmp/linux-setup-prereq.log"
if ! pacman -Syu --needed git curl >"$prereq_log" 2>&1; then
  warn "No se pudieron instalar todos los prerrequisitos iniciales. El script intentará continuar."
  warn "Detalle del fallo en $prereq_log:"
  sed -n '1,20p' "$prereq_log" | while IFS= read -r line; do warn "  $line"; done
fi

# ------------------------------------------------------------------------------
# Registro de herramientas: id | etiqueta | función instalar | función chequear
# ------------------------------------------------------------------------------
register_tool update   "Actualización de Sistema"    install_update            check_update
register_tool flatpak  "Soporte Flatpak"             install_flatpak           check_flatpak
register_tool zsh      "Zsh & Oh My Zsh"             install_zsh_ohmyzsh       check_zsh
register_tool yazi     "Yazi File Manager"           install_yazi              check_yazi
register_tool neovim   "Neovim & LazyVim"            install_neovim_lazyvim    check_neovim
register_tool lazygit  "Lazygit"                     install_lazygit           check_lazygit
register_tool pokemon  "Pokemon Colorscripts"        install_pokemon_colorscripts check_pokemon
register_tool node     "Node.js & npm"                install_nodejs_npm       check_nodejs
register_tool gemini   "Gemini Copilot (cli)"        install_gemini_copilot   check_gemini
register_tool brave    "Brave Browser"               install_brave             check_brave
register_tool spotify  "Spotify (Flatpak)"           install_spotify           check_spotify
register_tool obsidian "Obsidian (Flatpak)"          install_obsidian          check_obsidian
register_tool dank     "Dank Material Shell"         install_dank_shell        check_dank
register_tool antigravity "Antigravity CLI"          install_antigravity       check_antigravity
register_tool configs  "Configs Niri"                install_configs           check_configs
register_tool plugins  "Plugins Zsh"                 install_zsh_plugins       check_plugins
register_tool zshrc    "Configuración .zshrc"        configure_zshrc           check_zshrc

main_menu "INSTALADOR CACHYOS"
