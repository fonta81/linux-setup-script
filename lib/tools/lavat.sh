#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 13. Lavat
install_lavat() {
  header "Instalando Lavat (lava lamp en la terminal)"
  if ! ensure_brew; then
    error "Sin Homebrew no se puede instalar Lavat."
    RESULTS[lavat]="Error"
    return 1
  fi

  info "Instalando lavat con Homebrew..."
  if ! brew_install lavat; then
    error "Error al instalar Lavat."
    RESULTS[lavat]="Error"
    return 1
  fi

  if ! brew_has_binary lavat; then
    error "El instalador terminó pero 'lavat' no se encontró en $(brew_bin_dir)."
    RESULTS[lavat]="Error"
    return 1
  fi
  success "Lavat instalado correctamente."
  RESULTS[lavat]="Éxito"
}


check_lavat() {
  cmd_available lavat && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
