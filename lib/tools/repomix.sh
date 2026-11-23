#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 11. Repomix
install_repomix() {
  header "Instalando Repomix"
  # Dependencia: si el paso 'node' fue omitido, se instala aquí como efecto
  # secundario. No se toca RESULTS[node] porque el usuario no aceptó ese paso.
  if ! ensure_node_for "Repomix"; then
    error "Sin Node.js/npm no se puede instalar repomix."
    RESULTS[repomix]="Error"
    return 1
  fi

  info "Instalando repomix globalmente..."
  if npm_install_global "repomix" "repomix"; then
    success "Repomix instalado correctamente."
    warn "Nota: Recuerda reiniciar la terminal o ejecutar 'source ~/.zshrc' para poder usar el comando 'repomix'."
    RESULTS[repomix]="Éxito"
  else
    RESULTS[repomix]="Error"
    return 1
  fi
}


check_repomix() {
  { [ -f "$REAL_HOME/.npm-global/bin/repomix" ] || command -v repomix >/dev/null 2>&1; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
