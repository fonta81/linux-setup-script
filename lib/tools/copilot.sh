#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 10. Copilot CLI
install_copilot_cli() {
  header "Instalando Copilot CLI"
  info "Descargando el instalador oficial (https://gh.io/copilot-install)..."
  # -o pipefail: sin él, un curl fallido deja a bash sin entrada y devuelve 0.
  # Se ejecuta como root para que el script instale en /usr/local/bin
  # (su modo '| sudo bash' documentado); así queda visible para todos.
  if ! bash -o pipefail -c 'curl -fsSL https://gh.io/copilot-install | bash'; then
    error "Error al instalar Copilot CLI."
    RESULTS[copilot]="Error"
    return 1
  fi
  # Verificación: nunca reportar Éxito sin el binario (patrón yazi/lazygit).
  if ! command -v copilot >/dev/null 2>&1; then
    error "El instalador terminó pero 'copilot' no se encontró."
    RESULTS[copilot]="Error"
    return 1
  fi
  success "Copilot CLI instalado correctamente."
  RESULTS[copilot]="Éxito"
}


check_copilot() {
  command -v copilot >/dev/null 2>&1 &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
