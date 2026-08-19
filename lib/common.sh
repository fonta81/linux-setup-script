#!/usr/bin/env bash
# ==============================================================================
# common.sh — Funciones compartidas entre todos los scripts de instalación.
# No se ejecuta solo: cada script de distro hace `source lib/common.sh`.
# ==============================================================================

# --- Colores y mensajes -------------------------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ÉXITO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
header()  { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# --- Permisos y usuario real ---------------------------------------------
require_root_and_detect_user() {
  if [ "$EUID" -ne 0 ]; then
    warn "Este script requiere permisos de administrador para instalar paquetes del sistema."
    info "Re-ejecutando con sudo..."
    exec sudo "$0" "$@"
  fi

  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER:-}" != "root" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  else
    REAL_USER=$(whoami)
    REAL_HOME="$HOME"
  fi
  [ -z "$REAL_HOME" ] && REAL_HOME="/home/$REAL_USER"
  export REAL_USER REAL_HOME
}

run_as_user() {
  if [ "$REAL_USER" = "root" ]; then
    env HOME="$REAL_HOME" USER="root" "$@"
  else
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" USER="$REAL_USER" "$@"
  fi
}

# --- Registro de resultados (array asociativo en vez de 14 variables) ----
declare -gA RESULTS=()
declare -ga TOOL_ORDER=()   # preserva el orden de registro/menú

# register_tool <id> <etiqueta_menu> <nombre_funcion_install> <nombre_funcion_check>
declare -gA TOOL_LABEL=()
declare -gA TOOL_INSTALL_FN=()
declare -gA TOOL_CHECK_FN=()

register_tool() {
  local id="$1" label="$2" install_fn="$3" check_fn="$4"
  TOOL_ORDER+=("$id")
  TOOL_LABEL["$id"]="$label"
  TOOL_INSTALL_FN["$id"]="$install_fn"
  TOOL_CHECK_FN["$id"]="$check_fn"
  RESULTS["$id"]="No ejecutado"
}

# Helper genérico de estado: comando + args opcionales
# Uso: check_command_exists nvim
check_command_exists() {
  command -v "$1" >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}"
}

check_flatpak_app() {
  command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "$1" \
    && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}"
}

check_dir_exists() {
  [ -d "$1" ] && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}"
}

format_res() {
  local val="$1"
  case "$val" in
    Éxito)   echo -e "${GREEN}$val${NC}" ;;
    Error)   echo -e "${RED}$val${NC}" ;;
    *)       echo -e "${BLUE}$val${NC}" ;;
  esac
}

# --- Backup seguro antes de sobrescribir configs --------------------------
# Uso: backup_if_exists "$REAL_HOME/.config/niri"
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    local backup="${target}.bak-$(date +%s)"
    warn "Ya existe $target, se respalda en $backup"
    run_as_user mv "$target" "$backup"
  fi
}

# --- Funciones visuales mejoradas (barras, spinner, cajas) ---------------------

# Barra de progreso animada - Uso: progress_bar "Instalando paquete" 5
progress_bar() {
  local label="$1"
  local seconds="${2:-3}"
  local width=30
  local iterations=$((seconds * 4))
  
  printf "%s " "$label"
  for ((i = 0; i < iterations; i++)); do
    local percent=$((i * 100 / iterations))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r%s [" "$label"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percent"
    sleep 0.25
  done
  printf "\r%s [" "$label"
  printf "%${width}s" | tr ' ' '='
  printf "] 100%%\n"
}

# Spinner animado - Uso: run_with_spinner "comando" "Mensaje"
run_with_spinner() {
  local cmd="$1"
  local msg="${2:-Procesando}"
  local spinners=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
  local i=0
  
  # Ejecutar comando en background
  eval "$cmd" &
  local pid=$!
  
  while kill -0 $pid 2>/dev/null; do
    printf "\r${CYAN}${spinners[$i]}${NC} $msg"
    i=$(( (i + 1) % ${#spinners[@]} ))
    sleep 0.1
  done
  
  wait $pid
  local exit_code=$?
  printf "\r${GREEN}✓${NC} $msg\n"
  return $exit_code
}

# Dibujar una caja/panel - Uso: draw_box "Título" "Contenido línea 1" "Contenido línea 2"
draw_box() {
  local title="$1"
  shift
  local lines=("$@")
  local max_width=0
  
  # Encontrar ancho máximo
  max_width=${#title}
  for line in "${lines[@]}"; do
    if [ ${#line} -gt $max_width ]; then
      max_width=${#line}
    fi
  done
  max_width=$((max_width + 4))
  
  # Dibujar caja
  printf "┌─"
  printf '─%.0s' $(seq 1 $max_width)
  printf "─┐\n"
  
  if [ -n "$title" ]; then
    printf "│ ${BOLD}%-${max_width}s${NC} │\n" "$title"
    printf "├─"
    printf '─%.0s' $(seq 1 $max_width)
    printf "─┤\n"
  fi
  
  for line in "${lines[@]}"; do
    printf "│ %-${max_width}s │\n" "$line"
  done
  
  printf "└─"
  printf '─%.0s' $(seq 1 $max_width)
  printf "─┘\n"
}

# --- UI genérica ------------------------------------------------------------
show_status_table() {
  echo -e "\n${BOLD}${CYAN}Estado de las Herramientas${NC}"
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  printf "${CYAN}║${NC} %-60s ${CYAN}║${NC}\n" "# | Herramienta | Estado"
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
  
  local i=1
  for id in "${TOOL_ORDER[@]}"; do
    local check_fn="${TOOL_CHECK_FN[$id]}"
    local status_text="$($check_fn)"
    local label="${TOOL_LABEL[$id]}"
    
    # Truncar label si es muy largo
    if [ ${#label} -gt 35 ]; then
      label="${label:0:32}..."
    fi
    
    printf "${CYAN}║${NC} %2d ${BOLD}%-35s${NC} %b ${CYAN}║${NC}\n" "$i" "$label" "$status_text"
    i=$((i + 1))
  done
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

show_summary() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${BOLD}Resumen de Operaciones${NC}" 
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  for id in "${TOOL_ORDER[@]}"; do
    local label="${TOOL_LABEL[$id]}"
    local result="${RESULTS[$id]}"
    local formatted_res="$(format_res "$result")"
    
    # Determinar ícono según resultado
    local icon=""
    case "$result" in
      Éxito)              icon="${GREEN}✓${NC}" ;;
      Error)              icon="${RED}✗${NC}" ;;
      "Éxito (Ya existía)") icon="${YELLOW}◐${NC}" ;;
      Omitido)            icon="${BLUE}◌${NC}" ;;
      *)                  icon="${BLUE}○${NC}" ;;
    esac
    
    printf "  $icon %-38s : %b\n" "$label" "$formatted_res"
  done
  
  echo ""
}

install_all() {
  for id in "${TOOL_ORDER[@]}"; do
    "${TOOL_INSTALL_FN[$id]}"
  done
  clear; show_summary
}

install_interactive() {
  for id in "${TOOL_ORDER[@]}"; do
    echo -en "¿Instalar ${TOOL_LABEL[$id]}? [s/N]: "
    read -r val
    if [[ "$val" =~ ^[sS]$ ]]; then
      "${TOOL_INSTALL_FN[$id]}"
    else
      RESULTS["$id"]="Omitido"
    fi
  done
  clear; show_summary
}

# Menú interactivo con navegación por flechas (fallback a números)
interactive_main_menu() {
  local title="$1"
  local options=("Todo automático" "Interactivo" "Estado" "Salir")
  local selected=0
  
  while true; do
    clear
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $title"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    show_status_table
    
    echo -e "${BOLD}Opciones:${NC}"
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$selected" ]; then
        echo -e "  ${CYAN}${BOLD}➤ $((i+1)). ${options[$i]}${NC}"
      else
        echo -e "    $((i+1)). ${options[$i]}"
      fi
    done
    
    echo ""
    echo -e "${BOLD}Usa ↑/↓ para navegar, Enter para seleccionar, o escribe número (1-4):${NC}"
    
    # Leer input - soportar flechas y números
    read -rsn 1 input
    
    if [[ "$input" == "" ]]; then
      read -rsn 2 input  # Leer secuencia de flecha
    fi
    
    case "$input" in
      A) selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} )) ;;
      B) selected=$(( (selected + 1) % ${#options[@]} )) ;;
      1) selected=0 ;;
      2) selected=1 ;;
      3) selected=2 ;;
      4) selected=3 ;;
      "") # Enter presionado
        case $selected in
          0) install_all; read -p "Presiona Enter para continuar..." ;;
          1) install_interactive; read -p "Presiona Enter para continuar..." ;;
          2) show_status_table; read -p "Presiona Enter para continuar..." ;;
          3) exit 0 ;;
        esac
        ;;
    esac
  done
}

main_menu() {
  local title="$1"
  while true; do
    clear
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $title"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    show_status_table
    
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  1) ${BOLD}Todo automático${NC}"
    echo -e "  2) ${BOLD}Interactivo${NC}"
    echo -e "  3) ${BOLD}Estado${NC}"
    echo -e "  4) ${BOLD}Salir${NC}"
    echo ""
    
    read -p "${BOLD}Opción (1-4):${NC} " opt
    case $opt in
      1) install_all; read -p "Presiona Enter para continuar..." ;;
      2) install_interactive; read -p "Presiona Enter para continuar..." ;;
      3) show_status_table; read -p "Presiona Enter para continuar..." ;;
      4) exit 0 ;;
      *) warn "Opción inválida. Intenta de nuevo." ;;
    esac
  done
}

# --- Detección de Distribución y Funciones Auxiliares Distro-Específicas ----
detect_distro() {
  if [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
  elif [ -f /etc/arch-release ] || grep -q "cachyos" /etc/os-release 2>/dev/null; then
    DISTRO="cachyos"
  else
    DISTRO="unknown"
  fi
  export DISTRO
}

# Instalar paquetes con el gestor de paquetes apropiado (dnf/pacman)
install_package() {
  local packages=("$@")
  if [ "$DISTRO" = "fedora" ]; then
    dnf install -y "${packages[@]}"
  else
    pacman -S --noconfirm "${packages[@]}"
  fi
}

# Habilitar repositorio en el gestor de paquetes
enable_copr_or_aur() {
  local repo="$1"
  local distro_repo="$2"
  if [ "$DISTRO" = "fedora" ]; then
    dnf copr enable -y "$repo"
  else
    # En Arch/CachyOS se usa AUR, pero para este caso usamos pacman
    # Los repositorios típicos ya están configurados
    return 0
  fi
}

# Ejecutar comando diferente según distro
run_on_distro() {
  local cmd_fedora="$1"
  local cmd_cachyos="$2"
  if [ "$DISTRO" = "fedora" ]; then
    eval "$cmd_fedora"
  else
    eval "$cmd_cachyos"
  fi
}

# --- Funciones de Instalación Unificadas ----------------------------------

# 1. Actualizar el sistema
install_update() {
  header "Actualizando el sistema $DISTRO"
  if run_on_distro "dnf upgrade -y" "pacman -Syu --noconfirm"; then
    success "Sistema actualizado correctamente."; RESULTS[update]="Éxito"
  else
    error "Error al actualizar el sistema."; RESULTS[update]="Error"; return 1
  fi
}

# 2. Configurar Flatpak
install_flatpak() {
  header "Configurando Flatpak y Flathub"
  if [ "$DISTRO" = "cachyos" ]; then
    if ! pacman -S --noconfirm flatpak; then
      error "Error al instalar Flatpak."; RESULTS[flatpak]="Error"; return 1
    fi
  fi
  if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Repositorio Flathub configurado correctamente."; RESULTS[flatpak]="Éxito"
  else
    error "Error al agregar el repositorio Flathub."; RESULTS[flatpak]="Error"; return 1
  fi
}

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
  if ! install_package zsh; then
    error "Error al instalar Zsh."; RESULTS[zsh]="Error"; return 1
  fi

  if command -v chsh >/dev/null 2>&1; then
    info "Cambiando la shell predeterminada a Zsh para el usuario $REAL_USER..."
    chsh -s "$(which zsh)" "$REAL_USER"
  else
    warn "No se pudo encontrar 'chsh'. Por favor cambia tu shell manualmente a Zsh usando: chsh -s \$(which zsh)"
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
  if [ "$DISTRO" = "fedora" ]; then
    info "Habilitando el repositorio COPR para Yazi..."
    if ! enable_copr_or_aur "lihaohong/yazi" && ! install_package yazi; then
      error "Error al habilitar COPR o instalar Yazi."; RESULTS[yazi]="Error"; return 1
    fi
  else
    if ! install_package yazi; then
      error "Error al instalar Yazi."; RESULTS[yazi]="Error"; return 1
    fi
  fi
  success "Yazi instalado correctamente."; RESULTS[yazi]="Éxito"
}

# 5. Neovim y LazyVim
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  if [ "$DISTRO" = "fedora" ]; then
    info "Instalando Neovim, git, ripgrep y fd-find..."
    if ! install_package neovim git ripgrep fd-find; then
      error "Error al instalar Neovim o sus dependencias básicas."; RESULTS[neovim]="Error"; return 1
    fi
  else
    info "Instalando Neovim..."
    if ! install_package neovim; then
      error "Error al instalar Neovim."; RESULTS[neovim]="Error"; return 1
    fi
  fi

  if [ -d "$REAL_HOME/.config/nvim" ]; then
    warn "Ya existe un directorio de configuración en $REAL_HOME/.config/nvim. Respaldando..."
    backup_if_exists "$REAL_HOME/.config/nvim"
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
  if [ "$DISTRO" = "fedora" ]; then
    info "Habilitando el repositorio COPR para Lazygit..."
    enable_copr_or_aur "atim/lazygit"
    if ! install_package lazygit; then
      error "Error al habilitar COPR o instalar Lazygit."; RESULTS[lazygit]="Error"; return 1
    fi
  else
    if ! install_package lazygit; then
      error "Error al instalar Lazygit."; RESULTS[lazygit]="Error"; return 1
    fi
  fi
  success "Lazygit instalado correctamente."; RESULTS[lazygit]="Éxito"
}

# 7. Pokemon Colorscripts
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
    error "Error al instalar Pokemon Colorscripts."; RESULTS[pokemon]="Error"; return 1
  fi
  rm -rf "$temp_dir"
}

# 8. Gemini Copilot
install_gemini_copilot() {
  header "Instalando Gemini Copilot (Node.js & gemini-cli)"
  info "Instalando Node.js y npm..."
  if ! install_package nodejs npm; then
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

# 9. Brave Browser
install_brave() {
  header "Instalando Brave Browser"
  if [ "$DISTRO" = "fedora" ]; then
    if curl -fsS https://dl.brave.com/install.sh | sh; then
      success "Brave Browser instalado correctamente."; RESULTS[brave]="Éxito"
    else
      error "Error al instalar Brave Browser."; RESULTS[brave]="Error"; return 1
    fi
  else
    if install_package brave-browser; then
      success "Brave instalado correctamente."; RESULTS[brave]="Éxito"
    else
      error "Error al instalar Brave."; RESULTS[brave]="Error"; return 1
    fi
  fi
}

# 10. Spotify
install_spotify() {
  header "Instalando Spotify (Flatpak)"
  ensure_flatpak
  if flatpak install -y flathub com.spotify.Client; then
    success "Spotify instalado correctamente via Flatpak."; RESULTS[spotify]="Éxito"
  else
    error "Error al instalar Spotify."; RESULTS[spotify]="Error"; return 1
  fi
}

# 11. Obsidian
install_obsidian() {
  header "Instalando Obsidian (Flatpak)"
  ensure_flatpak
  if flatpak install -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado correctamente via Flatpak."; RESULTS[obsidian]="Éxito"
  else
    error "Error al instalar Obsidian."; RESULTS[obsidian]="Error"; return 1
  fi
}

# 12. Dank Shell
install_dank_shell() {
  header "Instalando Dank Material Shell"
  if curl -fsSL https://install.danklinux.com | sh; then
    success "Dank Material Shell instalado correctamente."; RESULTS[dank]="Éxito"
  else
    error "Error al instalar Dank Material Shell."; RESULTS[dank]="Error"; return 1
  fi
}

# 13. Configs Niri
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

# 14. Antigravity CLI
install_antigravity() {
  header "Instalando Antigravity CLI"
  if curl -fsSL https://antigravity.google/cli/install.sh | bash; then
    success "Antigravity CLI instalado correctamente."; RESULTS[antigravity]="Éxito"
  else
    error "Error al instalar Antigravity CLI."; RESULTS[antigravity]="Error"; return 1
  fi
}

# 15. Plugins Oh My Zsh
install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  if ! install_package zsh-autosuggestions zsh-syntax-highlighting; then
    error "Error al instalar paquetes de plugins."; RESULTS[plugins]="Error"; return 1
  fi
  
  # Rutas de origen según distro
  if [ "$DISTRO" = "fedora" ]; then
    local src_auto="/usr/share/zsh-autosuggestions"
    local src_syntax="/usr/share/zsh-syntax-highlighting"
  else
    local src_auto="/usr/share/zsh/plugins/zsh-autosuggestions"
    local src_syntax="/usr/share/zsh/plugins/zsh-syntax-highlighting"
  fi

  local custom_plugins_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  run_as_user mkdir -p "$custom_plugins_dir"
  run_as_user ln -snf "$src_auto" "$custom_plugins_dir/zsh-autosuggestions"
  run_as_user ln -snf "$src_syntax" "$custom_plugins_dir/zsh-syntax-highlighting"

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

# 16. Configurar .zshrc personalizado
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

# --- Funciones de Verificación Unificadas ---------------------------------

check_update() {
  echo -e "${BLUE}Listo para verificar/actualizar${NC}"
}

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

check_yazi() {
  command -v yazi >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ -d "$REAL_HOME/.config/nvim" ]; then
    echo -e "${GREEN}Instalado (con LazyVim)${NC}"
  elif command -v nvim >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Neovim (sin LazyVim)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}

check_lazygit() {
  command -v lazygit >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_pokemon() {
  { command -v pokemon-colorscripts >/dev/null 2>&1 || [ -f "/usr/local/bin/pokemon-colorscripts" ]; } \
    && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_gemini() {
  { [ -f "$REAL_HOME/.npm-global/bin/gemini" ] || command -v gemini >/dev/null 2>&1; } \
    && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_brave() {
  command -v brave-browser >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_spotify() {
  command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "com.spotify.Client" 2>/dev/null \
    && echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_obsidian() {
  command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application 2>/dev/null | grep -q "md.obsidian.Obsidian" 2>/dev/null \
    && echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_dank() {
  echo -e "${YELLOW}Verificación manual requerida${NC}"
}

check_antigravity() {
  command -v agy >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_configs() {
  check_dir_exists "$REAL_HOME/.config/niri"
}

check_plugins() {
  check_dir_exists "${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
}

check_zshrc() {
  if [ -f "$REAL_HOME/.zshrc" ] && grep -q "pokemon-colorscripts" "$REAL_HOME/.zshrc" 2>/dev/null; then
    echo -e "${GREEN}Configurado${NC}"
  elif [ -f "$REAL_HOME/.zshrc" ]; then
    echo -e "${YELLOW}Por defecto (sin personalización)${NC}"
  else
    echo -e "${RED}No instalado/configurado${NC}"
  fi
}

detect_distro

