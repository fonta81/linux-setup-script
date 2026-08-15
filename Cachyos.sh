#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Script de Auto-Instalación de Herramientas para CachyOS (Arch Linux)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_root_and_detect_user "$@"

info "Comprobando requisitos básicos (git, curl)..."
pacman -Sy --needed git curl >/dev/null 2>&1

# ------------------------------------------------------------------------------
# Funciones de instalación (específicas de pacman/CachyOS)
# ------------------------------------------------------------------------------

install_update() {
  header "Actualizando el sistema CachyOS"
  if pacman -Syu --noconfirm; then
    success "Sistema actualizado."; RESULTS[update]="Éxito"
  else
    error "Error al actualizar."; RESULTS[update]="Error"; return 1
  fi
}

install_flatpak() {
  header "Configurando Flatpak"
  if pacman -S --noconfirm flatpak && flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Flatpak configurado."; RESULTS[flatpak]="Éxito"
  else
    error "Error al configurar Flatpak."; RESULTS[flatpak]="Error"; return 1
  fi
}

install_zsh_ohmyzsh() {
  header "Instalando Zsh y Oh My Zsh"
  if pacman -S --noconfirm zsh; then
    chsh -s "$(which zsh)" "$REAL_USER"
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
      run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    success "Zsh y Oh My Zsh instalados."; RESULTS[zsh]="Éxito"
  else
    error "Error al instalar Zsh."; RESULTS[zsh]="Error"; return 1
  fi
}

install_yazi() {
  header "Instalando Yazi"
  if pacman -S --noconfirm yazi; then
    success "Yazi instalado."; RESULTS[yazi]="Éxito"
  else
    error "Error al instalar Yazi."; RESULTS[yazi]="Error"; return 1
  fi
}

install_neovim_lazyvim() {
  header "Instalando Neovim y LazyVim"
  if pacman -S --noconfirm neovim; then
    if [ -d "$REAL_HOME/.config/nvim" ]; then
      warn "Ya existe un directorio de configuración en $REAL_HOME/.config/nvim. Respaldando..."
      backup_if_exists "$REAL_HOME/.config/nvim"
    fi
    run_as_user git clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"
    run_as_user rm -rf "$REAL_HOME/.config/nvim/.git"
    success "Neovim y LazyVim configurados."; RESULTS[neovim]="Éxito"
  else
    error "Error al instalar Neovim."; RESULTS[neovim]="Error"; return 1
  fi
}

install_lazygit() {
  header "Instalando Lazygit"
  if pacman -S --noconfirm lazygit; then
    success "Lazygit instalado."; RESULTS[lazygit]="Éxito"
  else
    error "Error al instalar Lazygit."; RESULTS[lazygit]="Error"; return 1
  fi
}

install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  local temp_dir="/tmp/pokemon-colorscripts"
  run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir" || {
    error "No se pudo clonar el repositorio."; RESULTS[pokemon]="Error"; return 1
  }
  if (cd "$temp_dir" && ./install.sh); then
    rm -rf "$temp_dir"
    success "Pokemon Colorscripts instalado."; RESULTS[pokemon]="Éxito"
  else
    rm -rf "$temp_dir"
    error "Error al instalar Pokemon Colorscripts."; RESULTS[pokemon]="Error"; return 1
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
    success "Gemini Copilot instalado."; RESULTS[gemini]="Éxito"
  else
    error "Error al instalar Gemini Copilot."; RESULTS[gemini]="Error"; return 1
  fi
}

install_brave() {
  header "Instalando Brave Browser"
  if pacman -S --noconfirm brave-browser; then
    success "Brave instalado."; RESULTS[brave]="Éxito"
  else
    error "Error al instalar Brave."; RESULTS[brave]="Error"; return 1
  fi
}

install_spotify() {
  header "Instalando Spotify"
  if flatpak install -y flathub com.spotify.Client; then
    success "Spotify instalado."; RESULTS[spotify]="Éxito"
  else
    error "Error al instalar Spotify."; RESULTS[spotify]="Error"; return 1
  fi
}

install_obsidian() {
  header "Instalando Obsidian"
  if flatpak install -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado."; RESULTS[obsidian]="Éxito"
  else
    error "Error al instalar Obsidian."; RESULTS[obsidian]="Error"; return 1
  fi
}

install_dank_shell() {
  header "Instalando Dank Material Shell"
  if curl -fsSL https://install.danklinux.com | sh; then
    success "Dank Material Shell instalado."; RESULTS[dank]="Éxito"
  else
    error "Error al instalar Dank Material Shell."; RESULTS[dank]="Error"; return 1
  fi
}

install_configs() {
  header "Aplicando configuraciones personales"
  backup_if_exists "$REAL_HOME/.config/niri"
  if run_as_user git clone https://github.com/fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri"; then
    run_as_user rm -rf "$REAL_HOME/.config/niri/.git"
    success "Configuraciones aplicadas."; RESULTS[configs]="Éxito"
  else
    error "Error al aplicar configuraciones."; RESULTS[configs]="Error"; return 1
  fi
}

install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  if pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting; then
    local custom_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
    run_as_user mkdir -p "$custom_dir"
    run_as_user ln -snf /usr/share/zsh/plugins/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
    run_as_user ln -snf /usr/share/zsh/plugins/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"

    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      if run_as_user grep -q '^plugins=(' "$REAL_HOME/.zshrc"; then
        if ! run_as_user grep -q "plugins=.*$plugin" "$REAL_HOME/.zshrc"; then
          run_as_user sed -i "s/^plugins=(\([^)]*\))/plugins=(\1 $plugin)/" "$REAL_HOME/.zshrc"
          info "Plugin $plugin añadido a .zshrc."
        else
          info "Plugin $plugin ya estaba en .zshrc."
        fi
      else
        run_as_user bash -c "echo 'plugins=($plugin)' >> '$REAL_HOME/.zshrc'"
        info "Plugins list creada en .zshrc con $plugin."
      fi
    done
    success "Plugins configurados."; RESULTS[plugins]="Éxito"
  else
    error "Error al configurar plugins."; RESULTS[plugins]="Error"; return 1
  fi
}

# ------------------------------------------------------------------------------
# Funciones de chequeo de estado (específicas de esta distro/herramientas)
# ------------------------------------------------------------------------------

check_update()   { echo -e "${BLUE}Listo${NC}"; }
check_flatpak()  { check_command_exists flatpak; }
check_zsh()      { command -v zsh >/dev/null 2>&1 && [ -d "$REAL_HOME/.oh-my-zsh" ] && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}"; }
check_yazi()     { check_command_exists yazi; }
check_neovim()   { check_command_exists nvim; }
check_lazygit()  { check_command_exists lazygit; }
check_pokemon()  { check_command_exists pokemon-colorscripts; }
check_gemini()   { check_command_exists gemini; }
check_brave()    { check_command_exists brave-browser; }
check_spotify()  { check_flatpak_app com.spotify.Client; }
check_obsidian() { check_flatpak_app md.obsidian.Obsidian; }
check_dank()     { echo -e "${YELLOW}Verif. manual${NC}"; }
check_configs()  { check_dir_exists "$REAL_HOME/.config/niri"; }
check_plugins()  { check_dir_exists "${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"; }

# ------------------------------------------------------------------------------
# Registro de herramientas: id | etiqueta | función instalar | función chequear
# ------------------------------------------------------------------------------
register_tool update    "Actualización"          install_update            check_update
register_tool flatpak   "Flatpak"                install_flatpak           check_flatpak
register_tool zsh       "Zsh & Oh My Zsh"        install_zsh_ohmyzsh       check_zsh
register_tool yazi      "Yazi"                   install_yazi              check_yazi
register_tool neovim    "Neovim & LazyVim"       install_neovim_lazyvim    check_neovim
register_tool lazygit   "Lazygit"                install_lazygit           check_lazygit
register_tool pokemon   "Pokemon Colorscripts"   install_pokemon_colorscripts check_pokemon
register_tool gemini    "Gemini Copilot"         install_gemini_copilot    check_gemini
register_tool brave     "Brave Browser"          install_brave             check_brave
register_tool spotify   "Spotify"                install_spotify           check_spotify
register_tool obsidian  "Obsidian"               install_obsidian          check_obsidian
register_tool dank      "Dank Shell"             install_dank_shell        check_dank
register_tool configs   "Configs Niri"           install_configs           check_configs
register_tool plugins   "Plugins Zsh"            install_zsh_plugins       check_plugins

main_menu "INSTALADOR CACHYOS"
