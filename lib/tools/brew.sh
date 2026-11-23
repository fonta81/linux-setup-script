#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.

# --- Homebrew (Linuxbrew) ---------------------------------------------------
# Prefijo por defecto que usa el instalador oficial de brew.sh en Linux.
BREW_PREFIX_DEFAULT="/home/linuxbrew/.linuxbrew"


# Imprime el prefijo de Homebrew. Solo se soporta el prefijo de Linuxbrew: no se
# intenta localizar brew con 'command -v brew' como usuario porque sudo aplica
# secure_path y brew nunca aparecería en ese PATH (comprobado), así que esa
# detección era código muerto. Para un prefijo distinto:
#   BREW_PREFIX=/opt/homebrew ./Fedora.sh
brew_prefix() {
  printf '%s\n' "${BREW_PREFIX:-$BREW_PREFIX_DEFAULT}"
}


# Directorio de binarios de Homebrew. Vive FUERA del PATH de root: sin esto, una
# herramienta instalada por brew sería invisible para las verificaciones y los
# check_* se reportarían como 'No instalado' para siempre.
brew_bin_dir() {
  printf '%s\n' "$(brew_prefix)/bin"
}


# Homebrew está instalado si su ejecutable existe en el prefijo. Con el prefijo
# único soportado (ver brew_prefix) no hace falta una segunda búsqueda por PATH.
brew_installed() {
  [ -x "$(brew_bin_dir)/brew" ]
}


# El binario debe provenir de la fórmula que este paso acaba de instalar, no de
# un binario viejo que ya estuviera en el sistema: /usr/bin/yazi de pacman, o el
# /usr/local/bin/lavat que dejaba la versión anterior del script (make install)
# satisfacen igual un 'command -v' y darían un falso éxito tras brew install.
# Uso: brew_has_binary yazi || { error ...; RESULTS[x]="Error"; return 1; }
brew_has_binary() {
  [ -x "$(brew_bin_dir)/$1" ]
}


# Instala una o más fórmulas como $REAL_USER. El binario de brew va por ruta
# absoluta y el PATH se pasa explícito porque el de root no incluye el prefijo.
# No escribe RESULTS: el llamador decide (mismo criterio que install_flatpak_app).
brew_install() {
  local brew_bin
  brew_bin="$(brew_bin_dir)/brew"
  if [ ! -x "$brew_bin" ]; then
    error "Homebrew no está disponible en $brew_bin."
    return 1
  fi
  run_as_user env PATH="$(brew_bin_dir):$PATH" "$brew_bin" install --formula "$@"
}


# Dice si un binario está disponible para el usuario real, venga de donde venga:
# PATH de root, prefijo de Homebrew, ~/.local/bin o el PATH del usuario.
# Solo para los check_*: tras instalar una fórmula se usa brew_has_binary, que sí
# distingue el binario de brew de uno viejo del sistema. Ojo con la última
# cláusula: bajo 'sudo -u' el PATH es el secure_path, así que NO ve
# ~/.npm-global/bin ni ~/.opencode/bin (las de ~/.local/bin y brew sí se
# comprueban antes por ruta).
# Uso: cmd_available lazygit || { error ...; RESULTS[x]="Error"; return 1; }
cmd_available() {
  local bin="$1"
  command -v "$bin" >/dev/null 2>&1 && return 0
  [ -x "$(brew_bin_dir)/$bin" ] && return 0
  [ -x "$REAL_HOME/.local/bin/$bin" ] && return 0
  run_as_user bash -c "command -v '$bin'" >/dev/null 2>&1
}


# Homebrew (Linuxbrew)
# Añade a ~/.zshrc y ~/.bashrc el bloque guardado que trae el config shipped
# (config_zsh/<DISTRO>/.zshrc), de forma idempotente. No se confía solo en lo que
# hace el instalador oficial: este no escribe en ningún rc file, solo imprime las
# instrucciones eligiendo el rc según $SHELL, que bajo run_as_user no es fiable.
# Se escribe el bloque con guarda (y no un 'eval' desnudo) para que el shell
# siga arrancando si brew se desinstala. El paso 'zshrc' sobrescribe ~/.zshrc
# al final de todos modos; esta línea cubre el caso en el que ese paso no corrió.
activate_brew() {
  local brew_bin="$(brew_bin_dir)/brew"
  local eval_line="eval \"\$($brew_bin shellenv)\""
  local rc
  for rc in "$REAL_HOME/.zshrc" "$REAL_HOME/.bashrc"; do
    [ -f "$rc" ] || run_as_user touch "$rc"
    # Se busca la línea exacta que se escribiría abajo: así el bloque guardado
    # del config shipped cuenta como 'ya estaba', pero un 'brew shellenv' suelto
    # (de otro prefijo, o del brewup de otro tutorial) no engaña la detección.
    if run_as_user grep -qF "$eval_line" "$rc" 2>/dev/null; then
      info "brew shellenv ya estaba en $rc."
      continue
    fi
    if run_as_user bash -c "printf '%s\n' 'if [ -x $brew_bin ]; then' '$eval_line' 'fi' >> '$rc'"; then
      success "brew shellenv agregado a $rc."
    else
      warn "No se pudo agregar brew shellenv a $rc. Agrégalo a mano."
    fi
  done
}


# Instala Homebrew como $REAL_USER. No escribe RESULTS: el llamador decide
# (mismo criterio que ensure_nodejs_npm / install_flatpak_app).
install_brew_impl() {
  header "Instalando Homebrew"

  if brew_installed; then
    warn "Homebrew ya está instalado en $(brew_prefix). Se omite la instalación."
    return 0
  fi

  # Herramientas de compilación que Homebrew exige en Linux
  # (docs.brew.sh/Homebrew-on-Linux). No es fatal: brew puede seguir sin ellas.
  info "Instalando las herramientas de compilación que Homebrew necesita..."
  local deps_log="/tmp/linux-setup-brew-deps.log"
  if ! run_on_distro \
    "dnf group install -y development-tools && dnf install -y procps-ng curl file" \
    "pacman -S --noconfirm --needed base-devel procps-ng curl file git" \
    >"$deps_log" 2>&1; then
    warn "No se pudieron instalar todas las dependencias de compilación de Homebrew."
    warn "Detalle del fallo en $deps_log. Se intenta continuar de todos modos."
  fi

  # El instalador de brew.sh aborta con "Insufficient permissions to install
  # Homebrew" cuando /home/linuxbrew no existe: en modo NONINTERACTIVE su sudo es
  # 'sudo -n', que no puede pedir contraseña. Creando el directorio aquí como
  # root y dejándolo del usuario real, no necesita sudo en ningún momento.
  if ! install -d -o "$REAL_USER" -g "$(id -gn "$REAL_USER")" /home/linuxbrew; then
    error "No se pudo crear /home/linuxbrew propiedad de $REAL_USER."
    return 1
  fi

  info "Ejecutando el instalador oficial como $REAL_USER (la primera vez clona el repo de Homebrew)..."
  # NUNCA como root: Homebrew se niega a correr como uid 0 (como dankinstall).
  # -o pipefail: sin él, un curl fallido deja a bash sin entrada y devuelve 0.
  if ! run_as_user env NONINTERACTIVE=1 bash -o pipefail -c \
    'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash'; then
    error "Error al instalar Homebrew."
    return 1
  fi

  if ! brew_installed; then
    error "El instalador terminó pero 'brew' no se encontró en $(brew_bin_dir)."
    return 1
  fi

  activate_brew
  success "Homebrew instalado en $(brew_prefix)."
}


install_brew() {
  # El estado 'Ya existía' se decide aquí, no en la impl: si brew ya estaba, el
  # paso lo omite igual, pero el resumen lo distingue de una instalación real.
  local ya_existia=0
  brew_installed && ya_existia=1

  if ! install_brew_impl; then
    RESULTS[brew]="Error"
    return 1
  fi
  if [ "$ya_existia" -eq 1 ]; then
    RESULTS[brew]="Éxito (Ya existía)"
  else
    RESULTS[brew]="Éxito"
  fi
}


# Asegura Homebrew como dependencia de otro paso (yazi/lazygit/lazyssh/lavat).
# No escribe RESULTS: si el paso 'brew' fue omitido y esto lo instala como efecto
# secundario, su fila queda como el usuario la dejó ('Omitido'/'No ejecutado'),
# igual que ensure_node_for con Node.js.
ensure_brew() {
  if brew_installed; then
    return 0
  fi
  info "Homebrew no está instalado: se instala como dependencia de este paso."
  install_brew_impl
}


check_brew() {
  # Sin la ruta en el mensaje a propósito: status_w es 34 y el prefijo
  # (/home/linuxbrew/.linuxbrew) desbordaría la caja.
  brew_installed && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
