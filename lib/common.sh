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
