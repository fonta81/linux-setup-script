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

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ÉXITO]${NC} $1"; }
warn() { echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# --- Permisos y usuario real ---------------------------------------------
require_root_and_detect_user() {
  if [ "$EUID" -ne 0 ]; then
    warn "Este script requiere permisos de administrador para instalar paquetes del sistema."
    info "Re-ejecutando con sudo..."
    # Se preserva el intérprete: si se invocó como 'bash Fedora.sh', $0 solo
    # no sería ejecutable directamente.
    exec sudo bash "$0" "$@"
  fi

  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER:-}" != "root" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  else
    REAL_USER=$(whoami)
    REAL_HOME="$HOME"
  fi
  [ -z "$REAL_HOME" ] && REAL_HOME="/home/$REAL_USER"

  # Sin esto, ejecutar el script desde una shell de root desplegaría ~/.zshrc,
  # la config de niri y chsh sobre /root, y 'dank' fallaría (dankinstall se
  # niega a correr como root). Se espera './Fedora.sh' desde la sesión del usuario.
  if [ "$REAL_USER" = "root" ]; then
    error "Ejecutado como root: no se puede saber a qué usuario pertenecen las configs."
    error "Ejecuta el script desde tu sesión normal (no con sudo -i):"
    error "    ./$(basename "$0")"
    error "Si de verdad quieres instalarlo en root, usa 'SUDO_USER=<usuario> sudo -E ./$(basename "$0")'."
    exit 1
  fi

  export REAL_USER REAL_HOME
}

run_as_user() {
  local uid
  uid=$(id -u "$REAL_USER")
  local xdg=()
  [ -d "/run/user/$uid" ] && xdg+=(XDG_RUNTIME_DIR="/run/user/$uid")
  if [ "$REAL_USER" = "root" ]; then
    env HOME="$REAL_HOME" USER="root" "${xdg[@]}" "$@"
  else
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" USER="$REAL_USER" "${xdg[@]}" "$@"
  fi
}

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

# Helper genérico de estado: comando + args opcionales
# Uso: check_command_exists nvim
check_command_exists() {
  command -v "$1" >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}"
}

check_flatpak_app() {
  command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "$1" &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No${NC}"
}

check_dir_exists() {
  [ -d "$1" ] && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}"
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

# Crea un directorio temporal propiedad de $REAL_USER (mktemp -d crea en root
# con modo 700, y el usuario no podría clonar dentro). Imprime solo la ruta;
# los avisos van a stderr para no contaminar "$(...)".
make_tempdir() {
  local pattern="${1:-/tmp/linux-setup.XXXXXX}"
  local dir
  dir=$(mktemp -d "$pattern") || return 1
  if [ "$REAL_USER" != "root" ] && ! chown "$REAL_USER" "$dir" 2>/dev/null; then
    warn "No se pudo cambiar el propietario de $dir a $REAL_USER." >&2
  fi
  printf '%s\n' "$dir"
}

# Clona <url> en <target> de forma atómica: primero a un temporal, luego
# respaldo del destino y swap. Si el clon falla, la config existente no se toca.
# Se conserva el .git del clon para permitir 'git pull' futuro.
# Deja la ruta del respaldo en DEPLOY_BACKUP (vacío si no había nada que respaldar).
declare -g DEPLOY_BACKUP=""
declare -g DEPLOY_TMP=""
declare -g DEPLOY_TARGET=""
# Restauración ante Ctrl-C (INT/TERM) en la ventana entre el respaldo y el
# swap final: si el destino quedó ausente, se devuelve el respaldo.
_deploy_clone_abort() {
  if [ -n "${DEPLOY_TMP:-}" ] && [ -d "$DEPLOY_TMP" ]; then
    if [ -n "${DEPLOY_BACKUP:-}" ] && [ ! -e "${DEPLOY_TARGET:-/nonexistent}" ]; then
      run_as_user mv "$DEPLOY_BACKUP" "$DEPLOY_TARGET" 2>/dev/null
    fi
    rm -rf "$DEPLOY_TMP" 2>/dev/null
  fi
}
deploy_clone() {
  local url="$1" target="$2"
  local parent
  parent=$(dirname "$target")
  local base
  base=$(basename "$target")
  local tmp inner
  # En instalaciones frescas ~/.config puede no existir y mktemp fallaría:
  # se asegura el directorio padre como el usuario real antes del temporal.
  run_as_user mkdir -p "$parent" || {
    error "No se pudo crear el directorio padre $parent."
    return 1
  }
  tmp=$(make_tempdir "$parent/.${base}.new.XXXXXX") || {
    error "No se pudo crear el directorio temporal en $parent."
    return 1
  }
  inner="$tmp/$base"
  DEPLOY_TMP="$tmp"
  DEPLOY_TARGET="$target"
  DEPLOY_BACKUP=""
  trap _deploy_clone_abort INT TERM

  if ! run_as_user git clone "$url" "$inner"; then
    error "Error al clonar $url."
    trap - INT TERM
    rm -rf "$tmp"
    DEPLOY_TMP=""
    return 1
  fi

  DEPLOY_BACKUP=""
  if [ -e "$target" ]; then
    DEPLOY_BACKUP="${target}.bak-$(date +%s)"
    warn "Ya existe $target, se respalda en $DEPLOY_BACKUP"
    if ! run_as_user mv "$target" "$DEPLOY_BACKUP"; then
      error "No se pudo respaldar $target. No se modifica nada."
      trap - INT TERM
      rm -rf "$tmp"
      DEPLOY_TMP=""
      DEPLOY_BACKUP=""
      return 1
    fi
  fi

  if run_as_user mv "$inner" "$target"; then
    trap - INT TERM
    rm -rf "$tmp"
    DEPLOY_TMP=""
    return 0
  fi

  error "No se pudo colocar la config nueva en $target. Restaurando el respaldo."
  [ -n "$DEPLOY_BACKUP" ] && run_as_user mv "$DEPLOY_BACKUP" "$target"
  trap - INT TERM
  rm -rf "$tmp"
  DEPLOY_TMP=""
  return 1
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
  local spinners=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0

  # Ejecutar comando en background
  eval "$cmd" &
  local pid=$!

  while kill -0 $pid 2>/dev/null; do
    printf "\r${CYAN}${spinners[$i]}${NC} $msg"
    i=$(((i + 1) % ${#spinners[@]}))
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
  for id in "${TOOL_ORDER[@]}"; do
    echo -en "¿Instalar ${TOOL_LABEL[$id]}? [s/N]: "
    read -r val
    if [[ "$val" =~ ^[sS]$ ]]; then
      "${TOOL_INSTALL_FN[$id]}"
    else
      RESULTS["$id"]="Omitido"
    fi
  done
  clear
  show_summary
}

# Menú interactivo con navegación por flechas (fallback a números)
interactive_main_menu() {
  local title="$1"
  local options=("Todo automático" "Interactivo" "Estado" "Salir")
  local selected=0
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
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$selected" ]; then
        echo -e "  ${CYAN}${BOLD}➤ $((i + 1)). ${options[$i]}${NC}"
      else
        echo -e "    $((i + 1)). ${options[$i]}"
      fi
    done

    echo ""
    echo -e "${BOLD}Usa ↑/↓ para navegar, Enter para seleccionar, o escribe número (1-4):${NC}"

    # Leer input - soportar flechas y números
    read -rsn 1 input

    if [[ "$input" == "" ]]; then
      read -rsn 2 input # Leer secuencia de flecha
    fi

    case "$input" in
    A) selected=$(((selected - 1 + ${#options[@]}) % ${#options[@]})) ;;
    B) selected=$(((selected + 1) % ${#options[@]})) ;;
    1) selected=0 ;;
    2) selected=1 ;;
    3) selected=2 ;;
    4) selected=3 ;;
    "") # Enter presionado
      case $selected in
      0)
        install_all
        read -p "Presiona Enter para continuar..."
        ;;
      1)
        install_interactive
        read -p "Presiona Enter para continuar..."
        ;;
      2)
        show_status_table
        read -p "Presiona Enter para continuar..."
        ;;
      3) exit 0 ;;
      esac
      ;;
    esac
  done
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
  case "$DISTRO" in
  fedora) dnf install -y "${packages[@]}" ;;
  cachyos) pacman -S --noconfirm "${packages[@]}" ;;
  *)
    error "Distribución no soportada ($DISTRO): no se pueden instalar '${packages[*]}'."
    return 1
    ;;
  esac
}

# Habilitar repositorio en el gestor de paquetes (solo Fedora; fuera de
# Fedora no hace nada y devuelve 0)
enable_copr_or_aur() {
  local repo="$1"
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
  if run_on_distro "dnf upgrade --refresh -y" "pacman -Syu --noconfirm"; then
    success "Sistema actualizado correctamente."
    RESULTS[update]="Éxito"
  else
    error "Error al actualizar el sistema."
    RESULTS[update]="Error"
    return 1
  fi
}

# 2. Configurar Flatpak
install_flatpak() {
  header "Configurando Flatpak y Flathub"
  if [ "$DISTRO" = "fedora" ]; then
    info "Instalando Flatpak (idempotente si ya existe)..."
    if ! install_package flatpak; then
      error "Error al instalar Flatpak."
      RESULTS[flatpak]="Error"
      return 1
    fi
  elif [ "$DISTRO" = "cachyos" ]; then
    if ! pacman -S --noconfirm flatpak; then
      error "Error al instalar Flatpak."
      RESULTS[flatpak]="Error"
      return 1
    fi
  fi
  # El remoto se registra --user como el usuario real: no ensucia /var para
  # otros usuarios y spotify/obsidian instalan en ese mismo ámbito.
  if run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    success "Repositorio Flathub configurado correctamente (--user de $REAL_USER)."
    RESULTS[flatpak]="Éxito"
  else
    error "Error al agregar el repositorio Flathub."
    RESULTS[flatpak]="Error"
    return 1
  fi
}

ensure_flatpak() {
  # Se consulta como el usuario real (ámbito --user + system visibles).
  if ! run_as_user flatpak remote-list 2>/dev/null | grep -q "flathub" 2>/dev/null; then
    info "Configurando Flathub primero para dar soporte a las aplicaciones Flatpak..."
    install_flatpak
  fi
}

# 3. Instalar Zsh y Oh My Zsh
install_zsh_ohmyzsh() {
  header "Instalando Zsh y Oh My Zsh"
  info "Instalando Zsh..."
  if ! install_package zsh; then
    error "Error al instalar Zsh."
    RESULTS[zsh]="Error"
    return 1
  fi

  if command -v chsh >/dev/null 2>&1; then
    info "Cambiando la shell predeterminada de $REAL_USER a Zsh..."
    local zsh_bin
    zsh_bin=$(command -v zsh 2>/dev/null)
    # chsh falla (y no avisa) si zsh no está en /etc/shells: nodea el error
    if [ -n "$zsh_bin" ] && chsh -s "$zsh_bin" "$REAL_USER"; then
      success "Shell predeterminada de $REAL_USER: $zsh_bin"
    else
      warn "chsh no pudo cambiar la shell de $REAL_USER (probable: zsh no está en /etc/shells)."
      warn "Cámbiala a mano con: chsh -s \$(command -v zsh) $REAL_USER"
    fi
  else
    warn "No se pudo encontrar 'chsh'. Por favor cambia tu shell manualmente a Zsh usando: chsh -s \$(command -v zsh)"
  fi

  if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh ya parece estar instalado en $REAL_HOME/.oh-my-zsh."
    RESULTS[zsh]="Éxito (Ya existía)"
  else
    info "Instalando Oh My Zsh en modo unattended..."
    # curl primero a una variable: si falla, sh sin entrada daría un falso Éxito.
    # Se canaliza por pipe a 'sh -s' en vez de 'sh -c "$var"' (quoting/ARG_MAX).
    local omz_installer
    if ! omz_installer=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) ||
      [ -z "$omz_installer" ]; then
      error "No se pudo descargar el instalador de Oh My Zsh."
      RESULTS[zsh]="Error"
      return 1
    fi
    if printf '%s\n' "$omz_installer" | run_as_user env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -s -- --unattended; then
      success "Oh My Zsh instalado de manera exitosa."
      RESULTS[zsh]="Éxito"
    else
      error "Error durante la instalación de Oh My Zsh."
      RESULTS[zsh]="Error"
      return 1
    fi
  fi
}

# Detección compartida de Yazi: sirve para la verificación tras instalar y
# para check_yazi. Se consulta como el usuario real, porque desde root un
# 'command -v yazi' no ve un Yazi en ~/.local/bin (patrón dms_installed).
yazi_installed() {
  command -v yazi >/dev/null 2>&1 ||
    run_as_user bash -c 'command -v yazi' >/dev/null 2>&1 ||
    [ -x "$REAL_HOME/.local/bin/yazi" ]
}

# 4. Instalar Yazi
install_yazi() {
  header "Instalando Yazi (File Manager de Terminal)"
  if [ "$DISTRO" = "fedora" ]; then
    # No es fatal y va en un 'if' propio: encadenarlo con '&&' hacia el error
    # hacía que, si el COPR se habilitaba bien, install_package nunca corriera
    # y el paso cayera en 'Éxito' sin instalar nada. Se omite si ya está activo.
    if dnf copr list --enabled 2>/dev/null | grep -q "lihaohong/yazi"; then
      info "El COPR lihaohong/yazi ya está habilitado."
    elif ! enable_copr_or_aur "lihaohong/yazi"; then
      warn "No se pudo habilitar el COPR lihaohong/yazi; se intenta con los repos base."
    fi
  fi
  if ! install_package yazi; then
    error "Error al instalar Yazi."
    RESULTS[yazi]="Error"
    return 1
  fi
  # Verificación: nunca reportar Éxito sin el binario (patrón dank/antigravity)
  if ! yazi_installed; then
    error "El instalador terminó pero 'yazi' no se encontró para $REAL_USER."
    RESULTS[yazi]="Error"
    return 1
  fi
  success "Yazi instalado correctamente."
  RESULTS[yazi]="Éxito"
}

# 5. Neovim y LazyVim
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  if [ "$DISTRO" = "fedora" ]; then
    info "Instalando Neovim, git, ripgrep, fd-find y dependencias de LazyVim (fzf, gcc, make, unzip)..."
    if ! install_package neovim git ripgrep fd-find fzf gcc make unzip; then
      error "Error al instalar Neovim o sus dependencias básicas."
      RESULTS[neovim]="Error"
      return 1
    fi
    # El paquete Fedora 'fd-find' ya provee el binario 'fd' (el nombre
    # 'fdfind' es propio de Debian); el enlace solo hace falta si aparece
    # 'fdfind' sin que haya un 'fd' visible para el usuario real.
    # El enlace vive en su ~/.local/bin (que el .zshrc añade al PATH al final,
    # así que solo se verifica el archivo, no 'command -v', en esta sesión).
    if [ ! -e "$REAL_HOME/.local/bin/fd" ] && ! run_as_user bash -c 'command -v fd' >/dev/null 2>&1; then
      local fdfind_path
      fdfind_path=$(run_as_user bash -c 'command -v fdfind' 2>/dev/null)
      if [ -n "$fdfind_path" ]; then
        run_as_user mkdir -p "$REAL_HOME/.local/bin"
        if run_as_user ln -snf "$fdfind_path" "$REAL_HOME/.local/bin/fd"; then
          info "Creado enlace ~/.local/bin/fd -> $fdfind_path para las herramientas de Neovim."
          info "Estará en el PATH tras aplicar el paso 'Configuración .zshrc' y reabrir la terminal."
        fi
      fi
    fi
  else
    info "Instalando Neovim, git, ripgrep y fd..."
    # En Arch/CachyOS los paquetes son 'ripgrep' y 'fd' (binarios rg y fd),
    # que necesita LazyVim/telescope. Sin ellos el paso parecía correcto pero
    # el editor fallaba al usar la búsqueda de archivos.
    if ! install_package neovim git ripgrep fd; then
      error "Error al instalar Neovim o sus dependencias básicas."
      RESULTS[neovim]="Error"
      return 1
    fi
  fi

  info "Clonando la plantilla starter de LazyVim..."
  if deploy_clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"; then
    success "Neovim y LazyVim configurados de manera exitosa."
    RESULTS[neovim]="Éxito"
  else
    error "Error al configurar Neovim/LazyVim${DEPLOY_BACKUP:+ (respaldo previo en $DEPLOY_BACKUP)}."
    RESULTS[neovim]="Error"
    return 1
  fi
}

# 6. Instalar Lazygit
install_lazygit() {
  header "Instalando Lazygit"
  if [ "$DISTRO" = "fedora" ]; then
    # terra-release solo se instala si falta o si el repo terra no existe:
    # reinstalarlo en cada corrida es lento e innecesario.
    if rpm -q terra-release >/dev/null 2>&1 && dnf repolist enabled 2>/dev/null | grep -qi "terra"; then
      info "El repositorio Terra ya está habilitado."
    else
      info "Habilitando el repositorio Terra para Lazygit..."
      if ! dnf install -y --nogpgcheck \
        --repofrompath "terra-fyralabs,https://repos.fyralabs.com/terra\$releasever" \
        terra-release; then
        error "Error al habilitar el repositorio Terra."
        RESULTS[lazygit]="Error"
        return 1
      fi
    fi
    if ! install_package lazygit; then
      error "Error al instalar Lazygit."
      RESULTS[lazygit]="Error"
      return 1
    fi
  else
    if ! install_package lazygit; then
      error "Error al instalar Lazygit."
      RESULTS[lazygit]="Error"
      return 1
    fi
  fi
  # Verificación: nunca reportar Éxito sin el binario (patrón yazi/brave/antigravity)
  if ! command -v lazygit >/dev/null 2>&1; then
    error "El instalador terminó pero 'lazygit' no se encontró."
    RESULTS[lazygit]="Error"
    return 1
  fi
  success "Lazygit instalado correctamente."
  RESULTS[lazygit]="Éxito"
}

# 7. Pokemon Colorscripts
install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  # mktemp -d evita el /tmp con nombre fijo, que otro usuario podría crear antes
  local temp_dir
  temp_dir=$(make_tempdir /tmp/pokemon-colorscripts.XXXXXX) || {
    error "No se pudo crear el directorio temporal."
    RESULTS[pokemon]="Error"
    return 1
  }
  info "Clonando repositorio..."
  if ! run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir/repo"; then
    error "Error al clonar el repositorio de pokemon-colorscripts."
    RESULTS[pokemon]="Error"
    rm -rf "$temp_dir"
    return 1
  fi
  # install.sh copia a /usr/local/opt y symlinkea en /usr/local/bin: necesita root
  if (cd "$temp_dir/repo" && ./install.sh); then
    success "Pokemon Colorscripts instalado correctamente."
    RESULTS[pokemon]="Éxito"
  else
    error "Error al instalar Pokemon Colorscripts."
    RESULTS[pokemon]="Error"
    rm -rf "$temp_dir"
    return 1
  fi
  rm -rf "$temp_dir"
}

# 8. Gemini Copilot
install_gemini_copilot() {
  header "Instalando Gemini Copilot (Node.js & gemini-cli)"
  info "Instalando Node.js y npm..."
  if ! install_package nodejs npm; then
    error "Error al instalar Node.js o npm."
    RESULTS[gemini]="Error"
    return 1
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
    error "Error al instalar el paquete @google/gemini-cli de forma global."
    RESULTS[gemini]="Error"
    return 1
  fi
}

# 9. Brave Browser
install_brave() {
  header "Instalando Brave Browser"
  # El instalador oficial cubre ambas distros: dnf en Fedora y pacman en
  # CachyOS, donde Brave NO está en los repos oficiales (es AUR-only,
  # 'brave-bin') y el script cae a un helper AUR si encuentra uno.
  # -o pipefail: sin él, un curl fallido deja a sh sin entrada y devuelve 0.
  if bash -o pipefail -c 'curl -fsS https://dl.brave.com/install.sh | sh'; then
    if command -v brave-browser >/dev/null 2>&1; then
      success "Brave Browser instalado correctamente."
      RESULTS[brave]="Éxito"
    else
      error "El instalador terminó pero 'brave-browser' no se encontró."
      RESULTS[brave]="Error"
      return 1
    fi
  else
    error "Error al instalar Brave Browser."
    RESULTS[brave]="Error"
    return 1
  fi
}

# 10. Spotify
install_spotify() {
  header "Instalando Spotify (Flatpak --user)"
  ensure_flatpak
  if run_as_user flatpak install --user -y flathub com.spotify.Client; then
    success "Spotify instalado correctamente via Flatpak (--user)."
    RESULTS[spotify]="Éxito"
  else
    error "Error al instalar Spotify."
    RESULTS[spotify]="Error"
    return 1
  fi
}

# 11. Obsidian
install_obsidian() {
  header "Instalando Obsidian (Flatpak --user)"
  ensure_flatpak
  if run_as_user flatpak install --user -y flathub md.obsidian.Obsidian; then
    success "Obsidian instalado correctamente via Flatpak (--user)."
    RESULTS[obsidian]="Éxito"
  else
    error "Error al instalar Obsidian."
    RESULTS[obsidian]="Error"
    return 1
  fi
}

# 12. Dank Shell
# Detección compartida de DMS: sirve para el skip, para check_dank y para verificar tras instalar
dms_installed() {
  command -v dms >/dev/null 2>&1 || [ -x "$REAL_HOME/.local/bin/dms" ]
}

install_dank_shell() {
  header "Instalando Dank Material Shell"

  if dms_installed; then
    warn "Dank Material Shell ya está instalado. Se omite; usa 'dms' para reconfigurar o actualizar."
    RESULTS[dank]="Éxito (Ya existía)"
    return 0
  fi

  if [ "$REAL_USER" = "root" ]; then
    error "dankinstall se niega a ejecutarse como root y no hay un usuario real detectado."
    RESULTS[dank]="Error"
    return 1
  fi

  info "Se abrirá el instalador interactivo de Dank. Responde sus preguntas (compositor: niri/hyprland, terminal: ghostty/kitty, etc.)."
  info "Se ejecuta como $REAL_USER; si pide una contraseña de sudo, es la tuya."

  # -o pipefail es imprescindible: sin él, un curl fallido (red/404) devolvería 0
  if ! run_as_user bash -o pipefail -c 'curl -fsSL https://install.danklinux.com | sh'; then
    error "Error al instalar Dank Material Shell."
    warn "Revisa los logs del instalador en /tmp/dankinstall-*.log"
    RESULTS[dank]="Error"
    return 1
  fi

  if ! dms_installed; then
    error "El instalador terminó pero 'dms' no se encontró en el sistema."
    warn "Revisa los logs del instalador en /tmp/dankinstall-*.log"
    RESULTS[dank]="Error"
    return 1
  fi

  success "Dank Material Shell instalado correctamente."
  RESULTS[dank]="Éxito"
}

# 13. Configs Niri
install_configs() {
  header "Aplicando configuraciones personales"
  # Este paso reemplaza ~/.config/niri, incluida la que acababa de generar
  # dankinstall: se pide confirmación si ya existe algo.
  if [ -e "$REAL_HOME/.config/niri" ]; then
    warn "Esto reemplazará tu ~/.config/niri actual (se guardará un respaldo .bak-<epoch>)."
    echo -en "¿Continuar y reemplazar la config de Niri? [s/N]: "
    local ans
    read -r ans
    if [[ ! "$ans" =~ ^[sS]$ ]]; then
      info "Paso de Niri omitido por el usuario."
      RESULTS[configs]="Omitido"
      return 0
    fi
  fi
  if deploy_clone https://github.com/fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri"; then
    success "Configuraciones aplicadas correctamente."
    RESULTS[configs]="Éxito"
  else
    error "Error al aplicar configuraciones personales${DEPLOY_BACKUP:+ (respaldo previo en $DEPLOY_BACKUP)}."
    RESULTS[configs]="Error"
    return 1
  fi
}

# 14. Antigravity CLI
install_antigravity() {
  header "Instalando Antigravity CLI"
  info "Se instala como $REAL_USER para que el binario 'agy' quede en su HOME."
  # -o pipefail: sin él, un curl fallido deja a bash sin entrada y devuelve 0
  if run_as_user bash -o pipefail -c 'curl -fsSL https://antigravity.google/cli/install.sh | bash'; then
    # command -v del usuario real: el PATH de root no es el suyo
    if run_as_user bash -c 'command -v agy' >/dev/null 2>&1 || [ -x "$REAL_HOME/.local/bin/agy" ]; then
      success "Antigravity CLI instalado correctamente."
      RESULTS[antigravity]="Éxito"
    else
      error "El instalador terminó pero 'agy' no se encontró para $REAL_USER."
      RESULTS[antigravity]="Error"
      return 1
    fi
  else
    error "Error al instalar Antigravity CLI."
    RESULTS[antigravity]="Error"
    return 1
  fi
}

# 15. Plugins Oh My Zsh
install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  if ! install_package zsh-autosuggestions zsh-syntax-highlighting; then
    error "Error al instalar paquetes de plugins."
    RESULTS[plugins]="Error"
    return 1
  fi

  # Rutas de origen según distro (scripts .zsh provistos por el paquete)
  if [ "$DISTRO" = "fedora" ]; then
    local src_auto="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    local src_syntax="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  else
    local src_auto="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    local src_syntax="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi

  local custom_plugins_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  run_as_user mkdir -p "$custom_plugins_dir"
  # OMZ solo carga custom/plugins/<nombre>/<nombre>.plugin.zsh: el symlink
  # al directorio del sistema nunca cargaba ('plugin not found' en Fedora).
  # Se crea un bridge que hace source al .zsh del paquete.
  local plugin src_file plug_dir bridge
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    case "$plugin" in
    zsh-autosuggestions) src_file="$src_auto" ;;
    zsh-syntax-highlighting) src_file="$src_syntax" ;;
    esac
    if [ ! -f "$src_file" ]; then
      warn "No se encontró $src_file: el plugin $plugin quedará sin fuente."
      continue
    fi
    plug_dir="$custom_plugins_dir/$plugin"
    bridge="$plug_dir/$plugin.plugin.zsh"
    # Si existía el symlink antiguo al directorio, se reemplaza por el bridge.
    if [ -L "$plug_dir" ]; then
      run_as_user rm -f "$plug_dir"
    fi
    # No pisar un bridge/clon ajeno (p. ej. clon git del upstream con su
    # propio .plugin.zsh): solo se escribe si falta o si lo generamos antes.
    if run_as_user test -f "$bridge" 2>/dev/null &&
      ! run_as_user grep -q "Generado por linux-setup-script" "$bridge" 2>/dev/null; then
      warn "Se conserva el $bridge existente (no lo generó este script)."
      continue
    fi
    run_as_user mkdir -p "$plug_dir"
    run_as_user bash -c "printf '%s\n' '# Generado por linux-setup-script: puente al paquete del sistema.' '[ -f \"$src_file\" ] && source \"$src_file\"' > '$bridge'"
    info "Plugin $plugin disponible vía $bridge."
  done

  local zshrc="$REAL_HOME/.zshrc"
  [ -f "$zshrc" ] || run_as_user touch "$zshrc"

  # El grep debe reconocer tanto una lista de una línea como un bloque multilínea,
  # y el sed solo sirve en el primer caso: antes se anunciaba un "añadido" que
  # no ocurría cuando plugins=( está en su propia línea.
  # El carácter tras el nombre puede ser espacio, salto de línea o ')'.
  local plugin
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if run_as_user grep -qE "(^|[[:space:]])${plugin}([[:space:])]|$)" "$zshrc"; then
      info "Plugin $plugin ya estaba en .zshrc."
    elif run_as_user grep -qE '^plugins=\([[:space:]]*$' "$zshrc"; then
      info "La lista plugins=( de $zshrc es multilínea: no se modifica automáticamente."
      info "  Añade $plugin a mano si hace falta (el paso 'Configuración .zshrc' sobrescribe el archivo)."
    elif run_as_user grep -q '^plugins=([^)]*)' "$zshrc"; then
      if run_as_user sed -i "s/^plugins=(\([^)]*\))/plugins=(\1 $plugin)/" "$zshrc" &&
        run_as_user grep -qE "(^|[[:space:]])${plugin}([[:space:])]|$)" "$zshrc"; then
        info "Plugin $plugin añadido a .zshrc."
      else
        warn "No se pudo añadir $plugin a la lista plugins=( de $zshrc."
      fi
    else
      info "No se encontró una línea 'plugins=(...)' en $zshrc: se deja sin tocar."
      info "  Añade $plugin a mano si hace falta (el paso 'Configuración .zshrc' sobrescribe el archivo)."
    fi
  done
  success "Plugins de Oh My Zsh configurados."
  RESULTS[plugins]="Éxito"
}

# 16. Configurar .zshrc personalizado y Ghostty
configure_zshrc() {
  header "Configurando archivo .zshrc personalizado y Ghostty"
  local zshrc_dir
  case "$DISTRO" in
  fedora) zshrc_dir="$SCRIPT_DIR/config_zsh/Fedora" ;;
  cachyos) zshrc_dir="$SCRIPT_DIR/config_zsh/Cachyos" ;;
  *)
    error "Distribución desconocida ($DISTRO): no se qué .zshrc instalar."
    RESULTS[zshrc]="Error"
    return 1
    ;;
  esac
  local source_zshrc="$zshrc_dir/.zshrc"
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
    else
      error "Error al copiar el archivo .zshrc a $REAL_HOME."
      RESULTS[zshrc]="Error"
      return 1
    fi
  else
    error "No se encontró el archivo .zshrc de origen en $source_zshrc."
    RESULTS[zshrc]="Error"
    return 1
  fi

  local source_ghostty="$SCRIPT_DIR/config_ghostty/config"
  if [ -f "$source_ghostty" ]; then
    info "Instalando configuración de Ghostty en $REAL_HOME/.config/ghostty/..."
    run_as_user mkdir -p "$REAL_HOME/.config/ghostty"
    backup_if_exists "$REAL_HOME/.config/ghostty/config"
    if run_as_user cp -r "$source_ghostty" "$REAL_HOME/.config/ghostty/"; then
      success "Configuración de Ghostty instalada."
    else
      warn "No se pudo instalar la configuración de Ghostty. Continuando..."
    fi
  else
    warn "No se encontró el config de Ghostty en $source_ghostty. Omitiendo..."
  fi

  RESULTS[zshrc]="Éxito"
}

# --- Funciones de Verificación Unificadas ---------------------------------

check_update() {
  # Placeholder honesto: este paso siempre está disponible bajo demanda,
  # no hay un estado "actualizado" barato de verificar sin correr el upgrade.
  echo -e "${BLUE}Bajo demanda${NC}"
}

check_flatpak() {
  # remote-list como el usuario real (cubre remotos system + user).
  command -v flatpak >/dev/null 2>&1 && run_as_user flatpak remote-list 2>/dev/null | grep -q "flathub" 2>/dev/null &&
    echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No configurado${NC}"
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
  yazi_installed && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
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
  { command -v pokemon-colorscripts >/dev/null 2>&1 || [ -f "/usr/local/bin/pokemon-colorscripts" ]; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_gemini() {
  { [ -f "$REAL_HOME/.npm-global/bin/gemini" ] || command -v gemini >/dev/null 2>&1; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_brave() {
  command -v brave-browser >/dev/null 2>&1 && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_spotify() {
  # list como el usuario real: como root no se ven las apps --user.
  command -v flatpak >/dev/null 2>&1 && run_as_user flatpak list --columns=application 2>/dev/null | grep -q "com.spotify.Client" 2>/dev/null &&
    echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_obsidian() {
  command -v flatpak >/dev/null 2>&1 && run_as_user flatpak list --columns=application 2>/dev/null | grep -q "md.obsidian.Obsidian" 2>/dev/null &&
    echo -e "${GREEN}Instalado (Flatpak)${NC}" || echo -e "${RED}No instalado${NC}"
}

check_dank() {
  if dms_installed; then
    echo -e "${GREEN}Instalado${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}

check_antigravity() {
  { command -v agy >/dev/null 2>&1 || [ -x "$REAL_HOME/.local/bin/agy" ]; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}

check_configs() {
  check_dir_exists "$REAL_HOME/.config/niri"
}

check_plugins() {
  local base="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  if [ -f "$base/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ] &&
    [ -f "$base/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ]; then
    echo -e "${GREEN}Configurado${NC}"
  else
    echo -e "${RED}No${NC}"
  fi
}

check_zshrc() {
  local has_zshrc="no"
  local has_ghostty="no"
  [ -f "$REAL_HOME/.zshrc" ] && has_zshrc="si"
  [ -f "$REAL_HOME/.config/ghostty/config" ] && has_ghostty="si"

  if [ "$has_zshrc" = "si" ] && [ "$has_ghostty" = "si" ]; then
    echo -e "${GREEN}Configurado${NC}"
  elif [ "$has_zshrc" = "si" ]; then
    if grep -q "pokemon-colorscripts" "$REAL_HOME/.zshrc" 2>/dev/null; then
      echo -e "${YELLOW}Configurado (sin Ghostty)${NC}"
    else
      echo -e "${YELLOW}Por defecto (sin personalización)${NC}"
    fi
  else
    echo -e "${RED}No instalado/configurado${NC}"
  fi
}

detect_distro
