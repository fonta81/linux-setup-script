#!/usr/bin/env bash
# Funciones compartidas de interfaz, registro y menús.

# --- Colores y mensajes -------------------------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ÉXITO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# --- Registro de resultados (array asociativo en vez de 14 variables) ----
declare -gA RESULTS=()
declare -ga TOOL_ORDER=() # preserva el orden de registro/menú

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


format_res() {
  local val="$1"
  case "$val" in
  Éxito) echo -e "${GREEN}$val${NC}" ;;
  "Éxito (Ya existía)") echo -e "${YELLOW}$val${NC}" ;;
  Error) echo -e "${RED}$val${NC}" ;;
  *) echo -e "${BLUE}$val${NC}" ;;
  esac
}


# --- UI genérica ------------------------------------------------------------
# Anchos fijos: el borde no debe depender del largo del texto de estado.
# status_w >= largo de la etiqueta de estado más larga ("Por defecto (sin
# personalización)" = 34), si no la fila se sale de la caja.
show_status_table() {
  local num_w=2 label_w=35 status_w=34
  local inner=$((1 + num_w + 1 + label_w + 1 + status_w + 1))
  local bar
  bar=$(printf '─%.0s' $(seq 1 "$inner"))

  echo -e "\n${BOLD}${CYAN}Estado de las Herramientas${NC}"
  echo -e "${CYAN}╔${bar}╗${NC}"
  printf "${CYAN}║${NC} %${num_w}s %-${label_w}s %-${status_w}s ${CYAN}║${NC}\n" "#" "Herramienta" "Estado"
  echo -e "${CYAN}╠${bar}╣${NC}"

  local i=1
  for id in "${TOOL_ORDER[@]}"; do
    local check_fn="${TOOL_CHECK_FN[$id]}"
    local status_text="$($check_fn)"
    local label="${TOOL_LABEL[$id]}"

    # Truncar label si es muy largo
    if [ ${#label} -gt $label_w ]; then
      label="${label:0:$((label_w - 3))}..."
    fi

    # printf de bash cuenta bytes en el ancho de campo, no caracteres: un label
    # con acentos ("ó") dejaría la fila 1 carácter más corta. Se rellena a mano.
    local label_pad=$((label_w - ${#label}))
    [ "$label_pad" -lt 0 ] && label_pad=0

    # El texto de estado trae códigos ANSI: hay que medirlo sin ellos para padrar
    local plain
    plain=$(printf '%s' "$status_text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$((status_w - ${#plain}))
    [ "$pad" -lt 0 ] && pad=0

    printf "${CYAN}║${NC} %${num_w}d %b%${label_pad}s %b%${pad}s ${CYAN}║${NC}\n" \
      "$i" "${BOLD}${label}${NC}" "" "$status_text" ""
    i=$((i + 1))
  done
  echo -e "${CYAN}╚${bar}╝${NC}\n"
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
    Éxito) icon="${GREEN}✓${NC}" ;;
    Error) icon="${RED}✗${NC}" ;;
    "Éxito (Ya existía)") icon="${YELLOW}◐${NC}" ;;
    Omitido) icon="${BLUE}◌${NC}" ;;
    *) icon="${BLUE}○${NC}" ;;
    esac

    printf "  $icon %-38s : %b\n" "$label" "$formatted_res"
  done

  echo ""
}

install_all() {
  for id in "${TOOL_ORDER[@]}"; do
    "${TOOL_INSTALL_FN[$id]}"
  done
  clear
  show_summary
}

install_interactive() {
  # 'a' (sí a todo) vive solo aquí: el flag es local, así que una vuelta
  # siguiente al menú vuelve a preguntar. No afecta a las preguntas internas
  # de install_configs (Niri) ni a dankinstall.
  local auto="" val
  for id in "${TOOL_ORDER[@]}"; do
    if [[ -n "$auto" ]]; then
      echo -e "¿Instalar ${TOOL_LABEL[$id]}? ${BOLD}a${NC} (sí a todo)"
      "${TOOL_INSTALL_FN[$id]}"
      continue
    fi
    echo -en "¿Instalar ${TOOL_LABEL[$id]}? [s/N/a]: "
    read -r val
    case "$val" in
    s | S) "${TOOL_INSTALL_FN[$id]}" ;;
    a | A)
      auto=1
      info "Sí a todo activado: los pasos restantes se instalarán sin preguntar."
      "${TOOL_INSTALL_FN[$id]}"
      ;;
    *) RESULTS["$id"]="Omitido" ;;
    esac
  done
  clear
  show_summary
}

main_menu() {
  local title="$1"
  local bar
  bar=$(printf '─%.0s' $(seq 1 76))
  while true; do
    clear
    echo -e "${CYAN}${BOLD}╔${bar}╗${NC}"
    echo -e "${CYAN}║${NC}  $title"
    echo -e "${CYAN}╚${bar}╝${NC}"
    echo ""

    show_status_table

    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  1) ${BOLD}Todo automático${NC}"
    echo -e "  2) ${BOLD}Interactivo${NC}"
    echo -e "  3) ${BOLD}Estado${NC}"
    echo -e "  4) ${BOLD}Salir${NC}"
    echo ""

    read -rp "$(echo -e "${BOLD}Opción (1-4):${NC} ")" opt
    case $opt in
    1)
      install_all
      read -rp "Presiona Enter para continuar..."
      ;;
    2)
      install_interactive
      read -rp "Presiona Enter para continuar..."
      ;;
    3)
      show_status_table
      read -rp "Presiona Enter para continuar..."
      ;;
    4) exit 0 ;;
    *) warn "Opción inválida. Intenta de nuevo." ;;
    esac
  done
}

