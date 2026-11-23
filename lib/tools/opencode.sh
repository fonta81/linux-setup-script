#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# OpenCode CLI
install_opencode() {
  header "Instalando OpenCode CLI"
  info "Se instala como $REAL_USER para que el binario 'opencode' quede en su HOME."
  # -o pipefail: sin él, un curl fallido deja a bash sin entrada y devuelve 0
  if run_as_user bash -o pipefail -c 'curl -fsSL https://opencode.ai/install | bash'; then
    # command -v del usuario real: el PATH de root no es el suyo
    if run_as_user bash -c 'command -v opencode' >/dev/null 2>&1 || [ -x "$REAL_HOME/.opencode/bin/opencode" ]; then
      success "OpenCode CLI instalado correctamente."
      warn "Nota: Recuerda reiniciar la terminal o ejecutar 'source ~/.zshrc' para poder usar el comando 'opencode'."
      RESULTS[opencode]="Éxito"
    else
      error "El instalador terminó pero 'opencode' no se encontró para $REAL_USER."
      RESULTS[opencode]="Error"
      return 1
    fi
  else
    error "Error al instalar OpenCode CLI."
    RESULTS[opencode]="Error"
    return 1
  fi
}


check_opencode() {
  { command -v opencode >/dev/null 2>&1 || [ -x "$REAL_HOME/.opencode/bin/opencode" ]; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
