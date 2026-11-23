#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


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


check_antigravity() {
  { command -v agy >/dev/null 2>&1 || [ -x "$REAL_HOME/.local/bin/agy" ]; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
