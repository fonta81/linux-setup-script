#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.



# 8. Node.js y npm
# Helper de bajo nivel: instala el runtime y configura el prefijo global de npm.
# No escribe RESULTS (lo usa el paso 'node' y también la dependencia de 'gemini').
ensure_nodejs_npm() {
  info "Instalando Node.js y npm..."
  if ! install_package nodejs npm; then
    error "Error al instalar Node.js o npm."
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

  # Verificación: nunca reportar Éxito sin el runtime (patrón yazi/lazygit).
  # Se consulta desde root porque nodejs/npm son paquetes del sistema.
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    error "El instalador terminó pero 'node' o 'npm' no se encontraron."
    return 1
  fi
}


install_nodejs_npm() {
  header "Instalando Node.js y npm"
  if ensure_nodejs_npm; then
    success "Node.js y npm listos (prefijo global en $REAL_HOME/.npm-global)."
    RESULTS[node]="Éxito"
  else
    error "Error al instalar o configurar Node.js/npm."
    RESULTS[node]="Error"
    return 1
  fi
}


# Asegura Node.js/npm como dependencia de otro paso (gemini/repomix).
# No escribe RESULTS: si falta el runtime lo instala como efecto secundario
# (ver ensure_nodejs_npm) y el llamador decide su propio RESULTS.
# Uso: ensure_node_for <etiqueta-paso> || { error ...; RESULTS[x]="Error"; return 1; }
ensure_node_for() {
  local label="$1"
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    warn "Node.js/npm no están instalados: se instalan como dependencia de $label."
    ensure_nodejs_npm || return 1
  fi
}


# Instala un paquete npm global y verifica que el binario quedó visible para
# $REAL_USER (PATH o ~/.npm-global/bin). No escribe RESULTS; imprime sus
# propios errores para no duplicar mensajes en el llamador.
npm_install_global() {
  local pkg="$1" bin="$2"
  if ! run_as_user npm install -g "$pkg"; then
    error "Error al instalar el paquete $pkg de forma global."
    return 1
  fi
  if ! run_as_user bash -c "command -v $bin" >/dev/null 2>&1 && [ ! -x "$REAL_HOME/.npm-global/bin/$bin" ]; then
    error "npm terminó pero '$bin' no se encontró para $REAL_USER."
    return 1
  fi
}


check_nodejs() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo -e "${GREEN}Instalado${NC}"
  elif command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}Node.js (sin npm)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
