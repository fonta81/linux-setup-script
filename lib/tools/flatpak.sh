#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


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
    if ! install_package flatpak; then
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


# Instala una app Flatpak --user. Escribe RESULTS[$id]; el llamador es un
# wrapper de una línea para no tocar el registro en los entrypoints.
# Uso: install_flatpak_app <id> <flatpak-appid> <etiqueta>
install_flatpak_app() {
  local id="$1" appid="$2" label="$3"
  header "Instalando $label (Flatpak --user)"
  ensure_flatpak
  if run_as_user flatpak install --user -y flathub "$appid"; then
    success "$label instalado correctamente via Flatpak (--user)."
    RESULTS["$id"]="Éxito"
  else
    error "Error al instalar $label."
    RESULTS["$id"]="Error"
    return 1
  fi
}


check_flatpak() {
  # remote-list como el usuario real (cubre remotos system + user).
  command -v flatpak >/dev/null 2>&1 && run_as_user flatpak remote-list 2>/dev/null | grep -q "flathub" 2>/dev/null &&
    echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No configurado${NC}"
}


# Test silencioso (sin salida) de app Flatpak --user: devuelve 0 si está.
# No imprime nada porque check_* se captura vía $(...) en show_status_table.
check_flatpak_app_installed() {
  local appid="$1"
  command -v flatpak >/dev/null 2>&1 &&
    run_as_user flatpak list --columns=application 2>/dev/null | grep -q "$appid" 2>/dev/null
}
