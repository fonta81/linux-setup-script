#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 6. Instalar Lazygit
install_lazygit() {
  header "Instalando Lazygit"
  if ! ensure_brew; then
    error "Sin Homebrew no se puede instalar Lazygit."
    RESULTS[lazygit]="Error"
    return 1
  fi

  info "Instalando lazygit con Homebrew..."
  if ! brew_install lazygit; then
    error "Error al instalar Lazygit."
    RESULTS[lazygit]="Error"
    return 1
  fi
  # Verificación: nunca reportar Éxito sin el binario (patrón yazi/lavat/brave).
  # brew_has_binary, no cmd_available: un lazygit de un repo de distro previo no
  # cuenta como el de Homebrew.
  if ! brew_has_binary lazygit; then
    error "El instalador terminó pero 'lazygit' no se encontró en $(brew_bin_dir)."
    RESULTS[lazygit]="Error"
    return 1
  fi
  success "Lazygit instalado correctamente."
  RESULTS[lazygit]="Éxito"
}


check_lazygit() {
  cmd_available lazygit && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
