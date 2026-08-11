#!/usr/bin/env bash

# ==============================================================================
# Script de Auto-Instalación de Herramientas para Fedora
# Basado en plan.md
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

# Comprobación e instalación de prerrequisitos básicos
info "Comprobando e instalando requisitos básicos (git, curl, util-linux-user)..."
if ! dnf install -y git curl util-linux-user >/dev/null 2>&1; then
  warn "No se pudieron instalar todos los prerrequisitos iniciales. El script intentará continuar."
fi

# Variables para registrar el resultado de cada instalación en la sesión actual
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
res_zshrc="No ejecutado"

# ------------------------------------------------------------------------------
# Funciones de Instalación para cada Herramienta
# ------------------------------------------------------------------------------

# 1. Actualizar el sistema
install_update() {
  header "Actualizando el sistema Fedora"
  if dnf upgrade -y; then
    success "Sistema actualizado correctamente."
    res_update="Éxito"
  else
    error "Error al actualizar el sistema."
    res_update="Error"
    return 1
  fi
}

# 2. Configurar Flatpak
install_flatpak() {
  header "Configurando Flatpak y Flathub"
  if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Repositorio Flathub configurado correctamente."
    res_flatpak="Éxito"
  else
    error "Error al agregar el repositorio Flathub."
    res_flatpak="Error"
    return 1
  fi
}

# Función auxiliar para asegurar que Flatpak esté configurado
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
    # Cambiar shell por defecto para el usuario real
    if command -v chsh >/dev/null 2>&1; then
      info "Cambiando la shell predeterminada a Zsh para el usuario $REAL_USER..."
      chsh -s "$(which zsh)" "$REAL_USER"
    else
      warn "No se pudo encontrar 'chsh'. Por favor cambia tu shell manualmente a Zsh usando: chsh -s \$(which zsh)"
    fi
  else
    error "Error al instalar Zsh."
    res_zsh="Error"
    return 1
  fi

  # Instalar Oh My Zsh
  if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh ya parece estar instalado en $REAL_HOME/.oh-my-zsh."
    res_zsh="Éxito (Ya existía)"
  else
    info "Instalando Oh My Zsh en modo unattended..."
    if run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
      success "Oh My Zsh instalado de manera exitosa."
      res_zsh="Éxito"
    else
      error "Error durante la instalación de Oh My Zsh."
      res_zsh="Error"
      return 1
    fi
  fi
}

# 4. Instalar Yazi
install_yazi() {
  header "Instalando Yazi (File Manager de Terminal)"
  info "Habilitando el repositorio COPR para Yazi..."
  if dnf copr enable -y lihaohong/yazi && dnf install -y yazi; then
    success "Yazi instalado correctamente."
    res_yazi="Éxito"
  else
    error "Error al habilitar COPR o instalar Yazi."
    res_yazi="Error"
    return 1
  fi
}

# 5. Instalar Neovim y LazyVim
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  info "Instalando Neovim, git, ripgrep y fd-find..."
  if ! dnf install -y neovim git ripgrep fd-find; then
    error "Error al instalar Neovim o sus dependencias básicas."
    res_neovim="Error"
    return 1
  fi

  if [ -d "$REAL_HOME/.config/nvim" ]; then
    warn "Ya existe un directorio de configuración en $REAL_HOME/.config/nvim."
    echo -en "¿Deseas respaldar la configuración actual y clonar LazyVim? [s/N]: "
    read -r resp
    if [[ "$resp" =~ ^[sS]$ ]]; then
      local backup_dir="$REAL_HOME/.config/nvim.bak.$(date +%F_%H-%M-%S)"
      info "Respaldando configuración existente en $backup_dir..."
      if run_as_user mv "$REAL_HOME/.config/nvim" "$backup_dir"; then
        success "Respaldo creado."
      else
        error "No se pudo respaldar el directorio existente. Se cancela la configuración de LazyVim."
        res_neovim="Error"
        return 1
      fi
    else
      info "Se mantiene la configuración existente de Neovim. Omitiendo LazyVim."
      res_neovim="Éxito (Conservó previa)"
      return 0
    fi
  fi

  info "Clonando la plantilla starter de LazyVim..."
  if run_as_user git clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"; then
    run_as_user rm -rf "$REAL_HOME/.config/nvim/.git"
    success "Neovim y LazyVim configurados de manera exitosa."
    res_neovim="Éxito"
  else
    error "Error al clonar la plantilla de LazyVim."
    res_neovim="Error"
    return 1
  fi
}

# 6. Instalar Lazygit
install_lazygit() {
  header "Instalando Lazygit"
  info "Habilitando el repositorio COPR para Lazygit..."
  if dnf copr enable -y atim/lazygit && dnf install -y lazygit; then
    success "Lazygit instalado correctamente."
    res_lazygit="Éxito"
  else
    error "Error al habilitar COPR o instalar Lazygit."
    res_lazygit="Error"
    return 1
  fi
}

# 7. Instalar Pokemon Colorscripts
install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  local temp_dir="/tmp/pokemon-colorscripts"
  rm -rf "$temp_dir"

  info "Clonando repositorio..."
  if run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir"; then
    cd "$temp_dir" || {
      error "No se pudo ingresar al directorio temporal."
      res_pokemon="Error"
      return 1
    }
    info "Ejecutando script de instalación como root..."
    if ./install.sh; then
      success "Pokemon Colorscripts instalado correctamente."
      res_pokemon="Éxito"
    else
      error "Error al ejecutar el instalador de pokemon-colorscripts."
      res_pokemon="Error"
    fi
    cd - >/dev/null || true
    rm -rf "$temp_dir"
  else
    error "Error al clonar el repositorio de pokemon-colorscripts."
    res_pokemon="Error"
    return 1
  fi
}

# 8. Instalar Gemini Copilot
install_gemini_copilot() {
  header "Instalando Gemini Copilot (Node.js & gemini-cli)"
  info "Instalando Node.js y npm..."
  if ! dnf install -y nodejs npm; then
    error "Error al instalar Node.js o npm."
    res_gemini="Error"
    return 1
  fi

  info "Configurando el prefijo de npm global para evitar el uso de sudo..."
  run_as_user mkdir -p "$REAL_HOME/.npm-global"
  run_as_user npm config set prefix "$REAL_HOME/.npm-global"

  # Asegurar existencia de .zshrc y .bashrc
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
    res_gemini="Éxito"
  else
    error "Error al instalar el paquete @google/gemini-cli de forma global."
    res_gemini="Error"
    return 1
  fi
}

# 9. Instalar Brave Browser
install_brave() {
  header "Instalando Brave Browser"
  if curl -fsS https://dl.brave.com/install.sh | sh; then
    success "Brave Browser instalado correctamente."
    res_brave="Éxito"
  else
    error "Error al instalar Brave Browser."
    res_brave="Error"
    return 1
  fi
}

# 10. Instalar Spotify
install_spotify() {
  header "Instalando Spotify (Flatpak)"
  ensure_flatpak

  if flatpak install -y flathub com.spotify.Client; then
    success "Spotify instalado correctamente via Flatpak."
    res_spotify="Éxito"
  else
    error "Error al instalar Spotify."
    res_spotify="Error"
    return 1
  fi
}

# 11. Instalar Obsidian
install_obsidian() {
  header "Instalando Obsidian (Flatpak)"
  ensure_flatpak

  if flatpak install -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado correctamente via Flatpak."
    res_obsidian="Éxito"
  else
    error "Error al instalar Obsidian."
    res_obsidian="Error"
    return 1
  fi
}

# 12. Dank Material Shell
install_dank_shell() {
  header "Instalando Dank Material Shell"
  if curl -fsSL https://install.danklinux.com | sh; then
    success "Dank Material Shell instalado correctamente."
    res_dank="Éxito"
  else
    error "Error al instalar Dank Material Shell."
    res_dank="Error"
    return 1
  fi
}

# 13. My configs (Niri)
install_configs() {
  header "Aplicando configuraciones personales"
  if run_as_user git clone git@github.com:fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri/.BackNiriDank"; then
    run_as_user rm -rf "$REAL_HOME/.config/niri" && run_as_user mv "$REAL_HOME/.config/niri/.BackNiriDank" "$REAL_HOME/.config/niri"
    success "Configuraciones aplicadas correctamente."
    res_configs="Éxito"
  else
    error "Error al aplicar configuraciones personales."
    res_configs="Error"
    return 1
  fi
}

# 14. Plugins Oh My Zsh
install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  
  if ! dnf install -y zsh-autosuggestions zsh-syntax-highlighting; then
    error "Error al instalar paquetes de plugins."
    res_zsh_plugins="Error"
    return 1
  fi
  
  local custom_plugins_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  run_as_user mkdir -p "$custom_plugins_dir"
  run_as_user ln -snf /usr/share/zsh-autosuggestions "$custom_plugins_dir/zsh-autosuggestions"
  run_as_user ln -snf /usr/share/zsh-syntax-highlighting "$custom_plugins_dir/zsh-syntax-highlighting"
  
  # Check and update .zshrc safely
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      if run_as_user grep -q '^plugins=(' "$REAL_HOME/.zshrc"; then
          # Check if plugin is already in plugins=(...)
          if ! run_as_user grep -q "plugins=.*$plugin" "$REAL_HOME/.zshrc"; then
              # Edit plugins=(...) to add plugin safely using sed
              run_as_user sed -i "s/^plugins=(\([^)]*\))/plugins=(\1 $plugin)/" "$REAL_HOME/.zshrc"
              info "Plugin $plugin añadido a .zshrc."
          else
              info "Plugin $plugin ya estaba en .zshrc."
          fi
      else
          # Create plugins line if it doesn't exist
          run_as_user bash -c "echo 'plugins=($plugin)' >> '$REAL_HOME/.zshrc'"
          info "Plugins list creada en .zshrc con $plugin."
      fi
  done
  
  success "Plugins de Oh My Zsh configurados."
  res_zsh_plugins="Éxito"
}

# 15. Configurar .zshrc personalizado
configure_zshrc() {
  header "Configurando archivo .zshrc personalizado"
  
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local source_zshrc="$script_dir/.zshrc"

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
      success ".zshrc configurado de manera exitosa."
      res_zshrc="Éxito"
    else
      error "Error al copiar el archivo .zshrc a $REAL_HOME."
      res_zshrc="Error"
      return 1
    fi
  else
    error "No se encontró el archivo .zshrc de origen en $source_zshrc."
    res_zshrc="Error (No encontrado)"
    return 1
  fi
}


# ------------------------------------------------------------------------------
# Funciones de Interfaz, Estados y Control
# ------------------------------------------------------------------------------

# Verificar estado de cada componente en el sistema
check_status() {
  local tool="$1"
  case "$tool" in
  update)
    echo -e "${BLUE}Listo para verificar/actualizar${NC}"
    ;;
  flatpak)
    if command -v flatpak >/dev/null 2>&1 && flatpak remote-list 2>/dev/null | grep -q "flathub" 2>/dev/null; then
      echo -e "${GREEN}Configurado${NC}"
    else
      echo -e "${RED}No configurado${NC}"
    fi
    ;;
  zsh)
    if command -v zsh >/dev/null 2>&1 && [ -d "$REAL_HOME/.oh-my-zsh" ]; then
      echo -e "${GREEN}Instalado (con Oh My Zsh)${NC}"
    elif command -v zsh >/dev/null 2>&1; then
      echo -e "${YELLOW}Solo Zsh (sin Oh My Zsh)${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  yazi)
    if command -v yazi >/dev/null 2>&1; then
      echo -e "${GREEN}Instalado${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  neovim)
    if command -v nvim >/dev/null 2>&1 && [ -d "$REAL_HOME/.config/nvim" ]; then
      echo -e "${GREEN}Instalado (con LazyVim)${NC}"
    elif command -v nvim >/dev/null 2>&1; then
      echo -e "${YELLOW}Solo Neovim (sin LazyVim)${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  lazygit)
    if command -v lazygit >/dev/null 2>&1; then
      echo -e "${GREEN}Instalado${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  pokemon)
    if command -v pokemon-colorscripts >/dev/null 2>&1 || [ -f "/usr/local/bin/pokemon-colorscripts" ]; then
      echo -e "${GREEN}Instalado${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  gemini)
    if [ -f "$REAL_HOME/.npm-global/bin/gemini" ] || command -v gemini >/dev/null 2>&1; then
      echo -e "${GREEN}Instalado${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  brave)
    if command -v brave-browser >/dev/null 2>&1; then
      echo -e "${GREEN}Instalado${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  spotify)
    if command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "com.spotify.Client" 2>/dev/null; then
      echo -e "${GREEN}Instalado (Flatpak)${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  obsidian)
    if command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "md.obsidian.Obsidian" 2>/dev/null; then
      echo -e "${GREEN}Instalado (Flatpak)${NC}"
    else
      echo -e "${RED}No instalado${NC}"
    fi
    ;;
  dank)
    echo -e "${YELLOW}Verificación manual requerida${NC}"
    ;;
  configs)
    if [ -d "$REAL_HOME/.config/niri" ]; then
      echo -e "${GREEN}Configurado${NC}"
    else
      echo -e "${RED}No configurado${NC}"
    fi
    ;;
  plugins)
    if [ -d "${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
      echo -e "${GREEN}Configurado${NC}"
    else
      echo -e "${RED}No configurado${NC}"
    fi
    ;;
  zshrc)
    if [ -f "$REAL_HOME/.zshrc" ] && grep -q "pokemon-colorscripts" "$REAL_HOME/.zshrc" 2>/dev/null; then
      echo -e "${GREEN}Configurado${NC}"
    elif [ -f "$REAL_HOME/.zshrc" ]; then
      echo -e "${YELLOW}Por defecto (sin personalización)${NC}"
    else
      echo -e "${RED}No instalado/configurado${NC}"
    fi
    ;;
  esac
}

# Tabla de estado detallada
show_status_table() {
  echo -e "\n${BOLD}Estado de las herramientas en el sistema:${NC}"
  echo -e "--------------------------------------------------------"
  printf "%-35s %-25s\n" "Herramienta / Configuración" "Estado"
  echo -e "--------------------------------------------------------"
  printf "%-35s %b\n" "1. Actualización de Sistema" "$(check_status update)"
  printf "%-35s %b\n" "2. Repositorio Flathub" "$(check_status flatpak)"
  printf "%-35s %b\n" "3. Zsh & Oh My Zsh" "$(check_status zsh)"
  printf "%-35s %b\n" "4. Yazi File Manager" "$(check_status yazi)"
  printf "%-35s %b\n" "5. Neovim & LazyVim" "$(check_status neovim)"
  printf "%-35s %b\n" "6. Lazygit" "$(check_status lazygit)"
  printf "%-35s %b\n" "7. Pokemon Colorscripts" "$(check_status pokemon)"
  printf "%-35s %b\n" "8. Gemini Copilot (cli)" "$(check_status gemini)"
  printf "%-35s %b\n" "9. Brave Browser" "$(check_status brave)"
  printf "%-35s %b\n" "10. Spotify (Flatpak)" "$(check_status spotify)"
  printf "%-35s %b\n" "11. Obsidian (Flatpak)" "$(check_status obsidian)"
  printf "%-35s %b\n" "12. Dank Material Shell" "$(check_status dank)"
  printf "%-35s %b\n" "13. Configs Niri" "$(check_status configs)"
  printf "%-35s %b\n" "14. Plugins Zsh" "$(check_status plugins)"
  printf "%-35s %b\n" "15. Configuración .zshrc" "$(check_status zshrc)"
  echo -e "--------------------------------------------------------\n"
}

# Formateo de los resultados de instalación por sesión
format_res() {
  local val="$1"
  if [[ "$val" == Éxito* ]]; then
    echo -e "${GREEN}$val${NC}"
  elif [ "$val" = "Error" ]; then
    echo -e "${RED}Error${NC}"
  elif [ "$val" = "Omitido" ]; then
    echo -e "${YELLOW}Omitido${NC}"
  else
    echo -e "${BLUE}No ejecutado${NC}"
  fi
}

# Mostrar resumen detallado de las operaciones de la sesión actual
show_summary() {
  header "Resumen de Operaciones en la Sesión Actual"
  echo -e "--------------------------------------------------------"
  printf "%-35s %-25s\n" "Herramienta / Tarea" "Resultado"
  echo -e "--------------------------------------------------------"
  printf "%-35s %b\n" "Actualización de Sistema" "$(format_res "$res_update")"
  printf "%-35s %b\n" "Configuración Flathub" "$(format_res "$res_flatpak")"
  printf "%-35s %b\n" "Zsh & Oh My Zsh" "$(format_res "$res_zsh")"
  printf "%-35s %b\n" "Yazi File Manager" "$(format_res "$res_yazi")"
  printf "%-35s %b\n" "Neovim & LazyVim" "$(format_res "$res_neovim")"
  printf "%-35s %b\n" "Lazygit" "$(format_res "$res_lazygit")"
  printf "%-35s %b\n" "Pokemon Colorscripts" "$(format_res "$res_pokemon")"
  printf "%-35s %b\n" "Gemini Copilot" "$(format_res "$res_gemini")"
  printf "%-35s %b\n" "Brave Browser" "$(format_res "$res_brave")"
  printf "%-35s %b\n" "Spotify" "$(format_res "$res_spotify")"
  printf "%-35s %b\n" "Obsidian" "$(format_res "$res_obsidian")"
  printf "%-35s %b\n" "Dank Material Shell" "$(format_res "$res_dank")"
  printf "%-35s %b\n" "Configs Niri" "$(format_res "$res_configs")"
  printf "%-35s %b\n" "Plugins Zsh" "$(format_res "$res_zsh_plugins")"
  printf "%-35s %b\n" "Config .zshrc" "$(format_res "$res_zshrc")"
  echo -e "--------------------------------------------------------\n"
}

# Ejecutar instalación automática de absolutamente todo
install_all() {
  header "Iniciando instalación automática de todas las herramientas"

  install_update
  install_flatpak
  install_zsh_ohmyzsh
  install_yazi
  install_neovim_lazyvim
  install_lazygit
  install_pokemon_colorscripts
  install_gemini_copilot
  install_brave
  install_spotify
  install_obsidian
  install_dank_shell
  install_configs
  install_zsh_plugins
  configure_zshrc

  clear
  show_summary
}

# Función auxiliar para simplificar la selección interactiva
prompt_install() {
  local description="$1"
  local install_func="$2"
  local status_var_name="$3" # Nombre de la variable como string

  echo -en "¿Instalar $description? [s/N]: "
  local val
  read -r val
  if [[ "$val" =~ ^[sS]$ ]]; then
    $install_func
  else
    # Usamos eval para actualizar la variable de estado por su nombre
    eval "$status_var_name='Omitido'"
  fi
}

# Selección interactiva por parte del usuario
install_interactive() {
  header "Selección Interactiva de Herramientas"

  prompt_install "Actualización de Sistema" "install_update" "res_update"
  prompt_install "Flatpak y Flathub" "install_flatpak" "res_flatpak"
  prompt_install "Zsh & Oh My Zsh" "install_zsh_ohmyzsh" "res_zsh"
  prompt_install "Yazi (File Manager)" "install_yazi" "res_yazi"
  prompt_install "Neovim & LazyVim" "install_neovim_lazyvim" "res_neovim"
  prompt_install "Lazygit" "install_lazygit" "res_lazygit"
  prompt_install "Pokemon Colorscripts" "install_pokemon_colorscripts" "res_pokemon"
  prompt_install "Gemini Copilot" "install_gemini_copilot" "res_gemini"
  prompt_install "Brave Browser" "install_brave" "res_brave"
  prompt_install "Spotify (Flatpak)" "install_spotify" "res_spotify"
  prompt_install "Obsidian (Flatpak)" "install_obsidian" "res_obsidian"
  prompt_install "Dank Material Shell" "install_dank_shell" "res_dank"
  prompt_install "Configuraciones Niri" "install_configs" "res_configs"
  prompt_install "Plugins Zsh" "install_zsh_plugins" "res_zsh_plugins"
  prompt_install "Configuración .zshrc" "configure_zshrc" "res_zshrc"

  clear
  show_summary
}

# ------------------------------------------------------------------------------
# Loop Principal del Menú
# ------------------------------------------------------------------------------
main_menu() {
  while true; do
    clear
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "${CYAN}${BOLD}                 AUTOREINSTALLADOR DE HERRAMIENTAS - FEDORA             ${NC}"
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "Usuario real detectado: ${GREEN}${REAL_USER}${NC}"
    echo -e "Directorio de destino:  ${GREEN}${REAL_HOME}${NC}"

    show_status_table

    echo -e "${BOLD}Opciones de instalación:${NC}"
    echo -e "  1) Instalar ${BOLD}TODAS${NC} las herramientas automáticamente"
    echo -e "  2) Seleccionar ${BOLD}INTERACTIVAMENTE${NC} qué herramientas instalar"
    echo -e "  3) Mostrar estado de herramientas actual"
    echo -e "  4) Salir"
    echo
    read -p "Selecciona una opción [1-4]: " option

    case "$option" in
    1)
      install_all
      echo -en "\nPresiona [Enter] para continuar..."
      read -r
      ;;
    2)
      install_interactive
      echo -en "\nPresiona [Enter] para continuar..."
      read -r
      ;;
    3)
      clear
      show_status_table
      echo -en "\nPresiona [Enter] para volver al menú..."
      read -r
      ;;
    4)
      header "Saliendo"
      info "¡Hasta luego! Que tengas un excelente día."
      exit 0
      ;;
    *)
      error "Opción no válida. Intenta nuevamente."
      sleep 1.5
      ;;
    esac
  done
}

# Iniciar la interfaz interactiva
main_menu
