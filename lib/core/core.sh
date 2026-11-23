#!/usr/bin/env bash
# Funciones compartidas de usuario, sistema de archivos y distribución.

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

