#!/usr/bin/env bash

# ==============================================================================
# Script de Auto-Instalación de Herramientas para CachyOS (Arch Linux)
# Basado en Cachyos.md y Fedora.sh
# ==============================================================================

# Configuración de colores para la terminal
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m" # Sin Color

# Mensajes con estilo
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ÉXITO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# Verificar que se ejecute con permisos de root (sudo)
if [ "$EUID" -ne 0 ]; then
  warn "Este script requiere permisos de administrador para instalar paquetes del sistema."
  info "Re-ejecutando con sudo..."
  exec sudo "$0" "$@"
fi

# Obtener el usuario real que invocó sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  REAL_USER=$(whoami)
  REAL_HOME="$HOME"
fi

# Asegurarse de que REAL_HOME no esté vacío
if [ -z "$REAL_HOME" ]; then
  REAL_HOME="/home/$REAL_USER"
fi

# Función para ejecutar comandos como el usuario real
run_as_user() {
  if [ "$REAL_USER" = "root" ]; then
    env HOME="$REAL_HOME" USER="root" "$@"
  else
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" USER="$REAL_USER" "$@"
  fi
}

# Comprobación de prerrequisitos
info "Comprobando requisitos básicos (git, curl)..."
pacman -Sy --needed git curl >/dev/null 2>&1

# Variables para registrar el resultado de cada instalación
res_update="No ejecutado"
res_flatpak="No ejecutado"
res_zsh="No ejecutado"
res_yazi="No ejecutado"
res_neovim="No ejecutado"
res_lazygit="No ejecutado"
res_pokemon="No ejecutado"
res_gemini="No ejecutado"
res_brave="No ejecutado"
res_spotify="No ejecutado"
res_obsidian="No ejecutado"
res_dank="No ejecutado"
res_configs="No ejecutado"
res_zsh_plugins="No ejecutado"

# ------------------------------------------------------------------------------
# Funciones de Instalación
# ------------------------------------------------------------------------------

install_update() {
  header "Actualizando el sistema CachyOS"
  if pacman -Syu --noconfirm; then
    success "Sistema actualizado."
    res_update="Éxito"
  else
    error "Error al actualizar."
    res_update="Error"
    return 1
  fi
}

install_flatpak() {
  header "Configurando Flatpak"
  if pacman -S --noconfirm flatpak && flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Flatpak configurado."
    res_flatpak="Éxito"
  else
    error "Error al configurar Flatpak."
    res_flatpak="Error"
    return 1
  fi
}

install_zsh_ohmyzsh() {
  header "Instalando Zsh y Oh My Zsh"
  if pacman -S --noconfirm zsh; then
    chsh -s "$(which zsh)" "$REAL_USER"
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
      run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    success "Zsh y Oh My Zsh instalados."
    res_zsh="Éxito"
  else
    error "Error al instalar Zsh."
    res_zsh="Error"
    return 1
  fi
}

install_yazi() {
  header "Instalando Yazi"
  if pacman -S --noconfirm yazi; then
    success "Yazi instalado."
    res_yazi="Éxito"
  else
    error "Error al instalar Yazi."
    res_yazi="Error"
    return 1
  fi
}

install_neovim_lazyvim() {
  header "Instalando Neovim y LazyVim"
  if pacman -S --noconfirm neovim; then
    run_as_user git clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"
    run_as_user rm -rf "$REAL_HOME/.config/nvim/.git"
    success "Neovim y LazyVim configurados."
    res_neovim="Éxito"
  else
    error "Error al instalar Neovim."
    res_neovim="Error"
    return 1
  fi
}

install_lazygit() {
  header "Instalando Lazygit"
  if pacman -S --noconfirm lazygit; then
    success "Lazygit instalado."
    res_lazygit="Éxito"
  else
    error "Error al instalar Lazygit."
    res_lazygit="Error"
    return 1
  fi
}

install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  local temp_dir="/tmp/pokemon-colorscripts"
  run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir"
  cd "$temp_dir" || return 1
  if ./install.sh; then
    cd - >/dev/null || true
    rm -rf "$temp_dir"
    success "Pokemon Colorscripts instalado."
    res_pokemon="Éxito"
  else
    cd - >/dev/null || true
    rm -rf "$temp_dir"
    error "Error al instalar Pokemon Colorscripts."
    res_pokemon="Error"
    return 1
  fi
}

install_gemini_copilot() {
  header "Instalando Gemini Copilot"
  if pacman -S --noconfirm npm nodejs; then
    run_as_user mkdir -p "$REAL_HOME/.npm-global"
    run_as_user npm config set prefix "$REAL_HOME/.npm-global"
    
    if ! run_as_user grep -q '\.npm-global/bin' "$REAL_HOME/.zshrc" 2>/dev/null; then
      run_as_user bash -c "echo 'export PATH=\"\$HOME/.npm-global/bin:\$PATH\"' >> '$REAL_HOME/.zshrc'"
    fi
    
    run_as_user npm install -g @google/gemini-cli
    success "Gemini Copilot instalado."
    res_gemini="Éxito"
  else
    error "Error al instalar Gemini Copilot."
    res_gemini="Error"
    return 1
  fi
}

install_brave() {
  header "Instalando Brave Browser"
  if pacman -S --noconfirm brave-browser; then
    success "Brave instalado."
    res_brave="Éxito"
  else
    error "Error al instalar Brave."
    res_brave="Error"
    return 1
  fi
}

install_spotify() {
  header "Instalando Spotify"
  if flatpak install -y flathub com.spotify.Client; then
    success "Spotify instalado."
    res_spotify="Éxito"
  else
    error "Error al instalar Spotify."
    res_spotify="Error"
    return 1
  fi
}

install_obsidian() {
  header "Instalando Obsidian"
  if flatpak install -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado."
    res_obsidian="Éxito"
  else
    error "Error al instalar Obsidian."
    res_obsidian="Error"
    return 1
  fi
}

install_dank_shell() {
  header "Instalando Dank Material Shell"
  if curl -fsSL https://install.danklinux.com | sh; then
    success "Dank Material Shell instalado."
    res_dank="Éxito"
  else
    error "Error al instalar Dank Material Shell."
    res_dank="Error"
    return 1
  fi
}

install_configs() {
  header "Aplicando configuraciones personales"
  if run_as_user git clone https://github.com/fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri/.BackNiriDank"; then
    run_as_user rm -rf "$REAL_HOME/.config/niri"
    run_as_user mv "$REAL_HOME/.config/niri/.BackNiriDank" "$REAL_HOME/.config/niri"
    success "Configuraciones aplicadas."
    res_configs="Éxito"
  else
    error "Error al aplicar configuraciones."
    res_configs="Error"
    return 1
  fi
}

install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  if pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting; then
    local custom_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
    run_as_user mkdir -p "$custom_dir"
    run_as_user ln -snf /usr/share/zsh/plugins/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
    run_as_user ln -snf /usr/share/zsh/plugins/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"
    run_as_user sed -i 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' "$REAL_HOME/.zshrc"
    success "Plugins configurados."
    res_zsh_plugins="Éxito"
  else
    error "Error al configurar plugins."
    res_zsh_plugins="Error"
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Funciones de Interfaz, Estados y Control
# ------------------------------------------------------------------------------

check_status() {
  local tool="$1"
  case "$tool" in
  update) echo -e "${BLUE}Listo${NC}" ;;
  flatpak) command -v flatpak >/dev/null 2>&1 && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}" ;;
  zsh) command -v zsh >/dev/null 2>&1 && [ -d "$REAL_HOME/.oh-my-zsh" ] && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  yazi) command -v yazi >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  neovim) command -v nvim >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  lazygit) command -v lazygit >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  pokemon) command -v pokemon-colorscripts >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  gemini) command -v gemini >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  brave) command -v brave-browser >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  spotify) command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "com.spotify.Client" && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  obsidian) command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "md.obsidian.Obsidian" && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}" ;;
  dank) echo -e "${YELLOW}Verif. manual${NC}" ;;
  configs) [ -d "$REAL_HOME/.config/niri" ] && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}" ;;
  plugins) [ -d "${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}" ;;
  esac
}

show_status_table() {
  echo -e "\n${BOLD}Estado de las herramientas:${NC}"
  echo -e "--------------------------------------------------------"
  printf "%-35s %-25s\n" "Herramienta" "Estado"
  echo -e "--------------------------------------------------------"
  printf "%-35s %b\n" "1. Actualización" "$(check_status update)"
  printf "%-35s %b\n" "2. Flatpak" "$(check_status flatpak)"
  printf "%-35s %b\n" "3. Zsh & Oh My Zsh" "$(check_status zsh)"
  printf "%-35s %b\n" "4. Yazi" "$(check_status yazi)"
  printf "%-35s %b\n" "5. Neovim & LazyVim" "$(check_status neovim)"
  printf "%-35s %b\n" "6. Lazygit" "$(check_status lazygit)"
  printf "%-35s %b\n" "7. Pokemon Colorscripts" "$(check_status pokemon)"
  printf "%-35s %b\n" "8. Gemini Copilot" "$(check_status gemini)"
  printf "%-35s %b\n" "9. Brave Browser" "$(check_status brave)"
  printf "%-35s %b\n" "10. Spotify" "$(check_status spotify)"
  printf "%-35s %b\n" "11. Obsidian" "$(check_status obsidian)"
  printf "%-35s %b\n" "12. Dank Shell" "$(check_status dank)"
  printf "%-35s %b\n" "13. Configs Niri" "$(check_status configs)"
  printf "%-35s %b\n" "14. Plugins Zsh" "$(check_status plugins)"
  echo -e "--------------------------------------------------------\n"
}

format_res() {
  local val="$1"
  [[ "$val" == "Éxito" ]] && echo -e "${GREEN}$val${NC}" || [[ "$val" == "Error" ]] && echo -e "${RED}$val${NC}" || echo -e "${BLUE}$val${NC}"
}

show_summary() {
  header "Resumen de Operaciones"
  printf "%-35s %b\n" "Actualización:" "$(format_res "$res_update")"
  printf "%-35s %b\n" "Flatpak:" "$(format_res "$res_flatpak")"
  printf "%-35s %b\n" "Zsh:" "$(format_res "$res_zsh")"
  printf "%-35s %b\n" "Yazi:" "$(format_res "$res_yazi")"
  printf "%-35s %b\n" "Neovim:" "$(format_res "$res_neovim")"
  printf "%-35s %b\n" "Lazygit:" "$(format_res "$res_lazygit")"
  printf "%-35s %b\n" "Pokemon:" "$(format_res "$res_pokemon")"
  printf "%-35s %b\n" "Gemini:" "$(format_res "$res_gemini")"
  printf "%-35s %b\n" "Brave:" "$(format_res "$res_brave")"
  printf "%-35s %b\n" "Spotify:" "$(format_res "$res_spotify")"
  printf "%-35s %b\n" "Obsidian:" "$(format_res "$res_obsidian")"
  printf "%-35s %b\n" "Dank:" "$(format_res "$res_dank")"
  printf "%-35s %b\n" "Configs:" "$(format_res "$res_configs")"
  printf "%-35s %b\n" "Plugins:" "$(format_res "$res_zsh_plugins")"
}

install_all() {
  install_update; install_flatpak; install_zsh_ohmyzsh; install_yazi; install_neovim_lazyvim; install_lazygit; install_pokemon_colorscripts; install_gemini_copilot; install_brave; install_spotify; install_obsidian; install_dank_shell; install_configs; install_zsh_plugins
  clear; show_summary
}

prompt_install() {
  echo -en "¿Instalar $1? [s/N]: "; read -r val
  [[ "$val" =~ ^[sS]$ ]] && $2 || eval "$3='Omitido'"
}

install_interactive() {
  prompt_install "Actualización" "install_update" "res_update"
  prompt_install "Flatpak" "install_flatpak" "res_flatpak"
  prompt_install "Zsh" "install_zsh_ohmyzsh" "res_zsh"
  prompt_install "Yazi" "install_yazi" "res_yazi"
  prompt_install "Neovim" "install_neovim_lazyvim" "res_neovim"
  prompt_install "Lazygit" "install_lazygit" "res_lazygit"
  prompt_install "Pokemon" "install_pokemon_colorscripts" "res_pokemon"
  prompt_install "Gemini" "install_gemini_copilot" "res_gemini"
  prompt_install "Brave" "install_brave" "res_brave"
  prompt_install "Spotify" "install_spotify" "res_spotify"
  prompt_install "Obsidian" "install_obsidian" "res_obsidian"
  prompt_install "Dank" "install_dank_shell" "res_dank"
  prompt_install "Configs" "install_configs" "res_configs"
  prompt_install "Plugins" "install_zsh_plugins" "res_zsh_plugins"
  clear; show_summary
}

main_menu() {
  while true; do
    clear; echo -e "${CYAN}${BOLD}=== INSTALADOR CACHYOS ===${NC}\n"
    show_status_table
    echo -e "1) Todo automático\n2) Interactivo\n3) Estado\n4) Salir"
    read -p "Opción: " opt
    case $opt in
      1) install_all; read ;;
      2) install_interactive; read ;;
      3) show_status_table; read ;;
      4) exit 0 ;;
    esac
  done
}

main_menu
