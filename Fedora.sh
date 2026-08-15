#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Script de Auto-Instalación de Herramientas para Fedora
# Basado en plan.md
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_root_and_detect_user "$@"

info "Comprobando e instalando requisitos básicos (git, curl, util-linux-user)..."
if ! dnf install -y git curl util-linux-user >/dev/null 2>&1; then
  warn "No se pudieron instalar todos los prerrequisitos iniciales. El script intentará continuar."
fi

# ------------------------------------------------------------------------------
# Funciones de Instalación para cada Herramienta (específicas de dnf/Fedora)
# ------------------------------------------------------------------------------

# 1. Actualizar el sistema
install_update() {
  header "Actualizando el sistema Fedora"
  if dnf upgrade -y; then
    success "Sistema actualizado correctamente."; RESULTS[update]="Éxito"
  else
    error "Error al actualizar el sistema."; RESULTS[update]="Error"; return 1
  fi
}

# 2. Configurar Flatpak
install_flatpak() {
  header "Configurando Flatpak y Flathub"
  if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Repositorio Flathub configurado correctamente."; RESULTS[flatpak]="Éxito"
  else
    error "Error al agregar el repositorio Flathub."; RESULTS[flatpak]="Error"; return 1
  fi
}

# Función auxiliar para asegurar que Flatpak esté configurado antes de usarlo
ensure_flatpak() {
  if ! flatpak remote-list | grep -q "flathub" 2>/dev/null; then
    info "Configurando Flathub primero para dar soporte a las aplicaciones Flatpak..."
    install_flatpak
  fi
}

# 3. Instalar Zsh y Oh My Zsh
install_zsh_ohmyzsh() {
  header "Instalando Zsh y Oh My Zsh"

  info "Instalando Zsh..."
  if dnf install -y zsh; then
    if command -v chsh >/dev/null 2>&1; then
      info "Cambiando la shell predeterminada a Zsh para el usuario $REAL_USER..."
      chsh -s "$(which zsh)" "$REAL_USER"
    else
      warn "No se pudo encontrar 'chsh'. Por favor cambia tu shell manualmente a Zsh usando: chsh -s \$(which zsh)"
    fi
  else
    error "Error al instalar Zsh."; RESULTS[zsh]="Error"; return 1
  fi

  if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh ya parece estar instalado en $REAL_HOME/.oh-my-zsh."
    RESULTS[zsh]="Éxito (Ya existía)"
  else
    info "Instalando Oh My Zsh en modo unattended..."
    if run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
      success "Oh My Zsh instalado de manera exitosa."; RESULTS[zsh]="Éxito"
    else
      error "Error durante la instalación de Oh My Zsh."; RESULTS[zsh]="Error"; return 1
    fi
  fi
}

# 4. Instalar Yazi
install_yazi() {
  header "Instalando Yazi (File Manager de Terminal)"
  info "Habilitando el repositorio COPR para Yazi..."
  if dnf copr enable -y lihaohong/yazi && dnf install -y yazi; then
    success "Yazi instalado correctamente."; RESULTS[yazi]="Éxito"
  else
    error "Error al habilitar COPR o instalar Yazi."; RESULTS[yazi]="Error"; return 1
  fi
}

# 5. Instalar Neovim y LazyVim
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  info "Instalando Neovim, git, ripgrep y fd-find..."
  if ! dnf install -y neovim git ripgrep fd-find; then
    error "Error al instalar Neovim o sus dependencias básicas."; RESULTS[neovim]="Error"; return 1
  fi

  if [ -d "$REAL_HOME/.config/nvim" ]; then
    warn "Ya existe un directorio de configuración en $REAL_HOME/.config/nvim."
    echo -en "¿Deseas respaldar la configuración actual y clonar LazyVim? [s/N]: "
    read -r resp
    if [[ "$resp" =~ ^[sS]$ ]]; then
      backup_if_exists "$REAL_HOME/.config/nvim"
    else
      info "Se mantiene la configuración existente de Neovim. Omitiendo LazyVim."
      RESULTS[neovim]="Éxito (Conservó previa)"
      return 0
    fi
  fi

  info "Clonando la plantilla starter de LazyVim..."
  if run_as_user git clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"; then
    run_as_user rm -rf "$REAL_HOME/.config/nvim/.git"
    success "Neovim y LazyVim configurados de manera exitosa."; RESULTS[neovim]="Éxito"
  else
    error "Error al clonar la plantilla de LazyVim."; RESULTS[neovim]="Error"; return 1
  fi
}

# 6. Instalar Lazygit
install_lazygit() {
  header "Instalando Lazygit"
  info "Habilitando el repositorio COPR para Lazygit..."
  if dnf copr enable -y atim/lazygit && dnf install -y lazygit; then
    success "Lazygit instalado correctamente."; RESULTS[lazygit]="Éxito"
  else
    error "Error al habilitar COPR o instalar Lazygit."; RESULTS[lazygit]="Error"; return 1
  fi
}

# 7. Instalar Pokemon Colorscripts
install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  local temp_dir="/tmp/pokemon-colorscripts"
  rm -rf "$temp_dir"

  info "Clonando repositorio..."
  if ! run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir"; then
    error "Error al clonar el repositorio de pokemon-colorscripts."; RESULTS[pokemon]="Error"; return 1
  fi

  if (cd "$temp_dir" && ./install.sh); then
    success "Pokemon Colorscripts instalado correctamente."; RESULTS[pokemon]="Éxito"
  else
    error "Error al ejecutar el instalador de pokemon-colorscripts."; RESULTS[pokemon]="Error"
  fi
  rm -rf "$temp_dir"
}

# 8. Instalar Gemini Copilot
install_gemini_copilot() {
  header "Instalando Gemini Copilot (Node.js & gemini-cli)"
  info "Instalando Node.js y npm..."
  if ! dnf install -y nodejs npm; then
    error "Error al instalar Node.js o npm."; RESULTS[gemini]="Error"; return 1
  fi

  info "Configurando el prefijo de npm global para evitar el uso de sudo..."
  run_as_user mkdir -p "$REAL_HOME/.npm-global"
  run_as_user npm config set prefix "$REAL_HOME/.npm-global"

  [ ! -f "$REAL_HOME/.zshrc" ] && run_as_user touch "$REAL_HOME/.zshrc"
  [ ! -f "$REAL_HOME/.bashrc" ] && run_as_user touch "$REAL_HOME/.bashrc"

  info "Configurando variables de entorno en .zshrc..."
  if ! run_as_user grep -q '\.npm-global/bin' "$REAL_HOME/.zshrc" 2>/dev/null; then
    run_as_user bash -c "echo 'export PATH=\"\$HOME/.npm-global/bin:\$PATH\"' >> '$REAL_HOME/.zshrc'"
    success "PATH agregado a .zshrc."
  else
    info "El PATH ya estaba configurado en .zshrc."
  fi

  info "Configurando variables de entorno en .bashrc..."
  if ! run_as_user grep -q '\.npm-global/bin' "$REAL_HOME/.bashrc" 2>/dev/null; then
    run_as_user bash -c "echo 'export PATH=\"\$HOME/.npm-global/bin:\$PATH\"' >> '$REAL_HOME/.bashrc'"
    success "PATH agregado a .bashrc."
  else
    info "El PATH ya estaba configurado en .bashrc."
  fi

  info "Instalando @google/gemini-cli globalmente..."
  if run_as_user npm install -g @google/gemini-cli; then
    success "Gemini Copilot se ha instalado correctamente."
    warn "Nota: Recuerda reiniciar la terminal o ejecutar 'source ~/.zshrc' para poder usar el comando 'gemini'."
    RESULTS[gemini]="Éxito"
  else
    error "Error al instalar el paquete @google/gemini-cli de forma global."; RESULTS[gemini]="Error"; return 1
  fi
}

# 9. Instalar Brave Browser
install_brave() {
  header "Instalando Brave Browser"
  if curl -fsS https://dl.brave.com/install.sh | sh; then
    success "Brave Browser instalado correctamente."; RESULTS[brave]="Éxito"
  else
    error "Error al instalar Brave Browser."; RESULTS[brave]="Error"; return 1
  fi
}

# 10. Instalar Spotify
install_spotify() {
  header "Instalando Spotify (Flatpak)"
  ensure_flatpak
  if flatpak install -y flathub com.spotify.Client; then
    success "Spotify instalado correctamente via Flatpak."; RESULTS[spotify]="Éxito"
  else
    error "Error al instalar Spotify."; RESULTS[spotify]="Error"; return 1
  fi
}

# 11. Instalar Obsidian
install_obsidian() {
  header "Instalando Obsidian (Flatpak)"
  ensure_flatpak
  if flatpak install -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado correctamente via Flatpak."; RESULTS[obsidian]="Éxito"
  else
    error "Error al instalar Obsidian."; RESULTS[obsidian]="Error"; return 1
  fi
}

# 12. Dank Material Shell
install_dank_shell() {
  header "Instalando Dank Material Shell"
  if curl -fsSL https://install.danklinux.com | sh; then
    success "Dank Material Shell instalado correctamente."; RESULTS[dank]="Éxito"
  else
    error "Error al instalar Dank Material Shell."; RESULTS[dank]="Error"; return 1
  fi
}

# 13. Mis configs (Niri)
install_configs() {
  header "Aplicando configuraciones personales"
  backup_if_exists "$REAL_HOME/.config/niri"
  if run_as_user git clone https://github.com/fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri"; then
    run_as_user rm -rf "$REAL_HOME/.config/niri/.git"
    success "Configuraciones aplicadas correctamente."; RESULTS[configs]="Éxito"
  else
    error "Error al aplicar configuraciones personales."; RESULTS[configs]="Error"; return 1
  fi
}

# 14. Plugins Oh My Zsh
install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"

  if ! dnf install -y zsh-autosuggestions zsh-syntax-highlighting; then
    error "Error al instalar paquetes de plugins."; RESULTS[plugins]="Error"; return 1
  fi

  local custom_plugins_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  run_as_user mkdir -p "$custom_plugins_dir"
  run_as_user ln -snf /usr/share/zsh-autosuggestions "$custom_plugins_dir/zsh-autosuggestions"
  run_as_user ln -snf /usr/share/zsh-syntax-highlighting "$custom_plugins_dir/zsh-syntax-highlighting"

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

  success "Plugins de Oh My Zsh configurados."; RESULTS[plugins]="Éxito"
}

# 15. Configurar .zshrc personalizado
configure_zshrc() {
  header "Configurando archivo .zshrc personalizado"

  local source_zshrc="$SCRIPT_DIR/.zshrc"

  if [ -f "$source_zshrc" ]; then
    if [ -f "$REAL_HOME/.zshrc" ]; then
      local backup_zshrc="$REAL_HOME/.zshrc.bak.$(date +%F_%H-%M-%S)"
      info "Se detectó un archivo .zshrc existente. Creando respaldo en $backup_zshrc..."
      if run_as_user cp "$REAL_HOME/.zshrc" "$backup_zshrc"; then
        success "Respaldo creado."
      else
        warn "No se pudo crear el respaldo de .zshrc. Continuando..."
      fi
    fi

    info "Instalando el archivo .zshrc personalizado en $REAL_HOME..."
    if run_as_user cp "$source_zshrc" "$REAL_HOME/.zshrc"; then
      success ".zshrc configurado de manera exitosa."; RESULTS[zshrc]="Éxito"
    else
      error "Error al copiar el archivo .zshrc a $REAL_HOME."; RESULTS[zshrc]="Error"; return 1
    fi
  else
    error "No se encontró el archivo .zshrc de origen en $source_zshrc."
    RESULTS[zshrc]="Error (No encontrado)"
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Funciones de chequeo de estado (específicas de Fedora, con mensajes detallados)
# ------------------------------------------------------------------------------

check_update()   { echo -e "${BLUE}Listo para verificar/actualizar${NC}"; }

check_flatpak() {
  command -v flatpak >/dev/null 2>&1 && flatpak remote-list 2>/dev/null | grep -q "flathub" 2>/dev/null \
    && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No configurado${NC}"
}

check_zsh() {
  if command -v zsh >/dev/null 2>&1 && [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}Instalado (con Oh My Zsh)${NC}"
  elif command -v zsh >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Zsh (sin Oh My Zsh)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}

check_yazi()    { command -v yazi >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"; }

check_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ -d "$REAL_HOME/.config/nvim" ]; then
    echo -e "${GREEN}Instalado (con LazyVim)${NC}"
  elif command -v nvim >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Neovim (sin LazyVim)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}

check_lazygit()  { command -v lazygit >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"; }

check_pokemon() {
  { command -v pokemon-colorscripts >/dev/null 2>&1 || [ -f "/usr/local/bin/pokemon-colorscripts" ]; } \
    && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_gemini() {
  { [ -f "$REAL_HOME/.npm-global/bin/gemini" ] || command -v gemini >/dev/null 2>&1; } \
    && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_brave()    { command -v brave-browser >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"; }

check_spotify() {
  command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "com.spotify.Client" 2>/dev/null \
    && echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_obsidian() {
  command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "md.obsidian.Obsidian" 2>/dev/null \
    && echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_dank()     { echo -e "${YELLOW}Verificación manual requerida${NC}"; }
check_configs()  { check_dir_exists "$REAL_HOME/.config/niri"; }
check_plugins()  { check_dir_exists "${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"; }

check_zshrc() {
  if [ -f "$REAL_HOME/.zshrc" ] && grep -q "pokemon-colorscripts" "$REAL_HOME/.zshrc" 2>/dev/null; then
    echo -e "${GREEN}Configurado${NC}"
  elif [ -f "$REAL_HOME/.zshrc" ]; then
    echo -e "${YELLOW}Por defecto (sin personalización)${NC}"
  else
    echo -e "${RED}No instalado/configurado${NC}"
  fi
}

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
register_tool configs  "Configs Niri"                install_configs           check_configs
register_tool plugins  "Plugins Zsh"                 install_zsh_plugins       check_plugins
register_tool zshrc    "Configuración .zshrc"        configure_zshrc           check_zshrc

main_menu "AUTOINSTALADOR DE HERRAMIENTAS - FEDORA"
