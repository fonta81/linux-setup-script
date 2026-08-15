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

# --- UI genérica ------------------------------------------------------------
show_status_table() {
  echo -e "\n${BOLD}Estado de las herramientas:${NC}"
  echo -e "--------------------------------------------------------"
  printf "%-35s %-25s\n" "Herramienta" "Estado"
  echo -e "--------------------------------------------------------"
  local i=1
  for id in "${TOOL_ORDER[@]}"; do
    local check_fn="${TOOL_CHECK_FN[$id]}"
    printf "%-35s %b\n" "$i. ${TOOL_LABEL[$id]}" "$($check_fn)"
    i=$((i + 1))
  done
  echo -e "--------------------------------------------------------\n"
}

show_summary() {
  header "Resumen de Operaciones"
  for id in "${TOOL_ORDER[@]}"; do
    printf "%-35s %b\n" "${TOOL_LABEL[$id]}:" "$(format_res "${RESULTS[$id]}")"
  done
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

main_menu() {
  local title="$1"
  while true; do
    clear; echo -e "${CYAN}${BOLD}=== $title ===${NC}\n"
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
