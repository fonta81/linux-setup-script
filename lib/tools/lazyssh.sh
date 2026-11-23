#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 12. LazySSH
install_lazyssh() {
  header "Instalando LazySSH"
  if ! ensure_brew; then
    error "Sin Homebrew no se puede instalar LazySSH."
    RESULTS[lazyssh]="Error"
    return 1
  fi

  info "Instalando lazyssh con Homebrew..."
  if ! brew_install lazyssh; then
    error "Error al instalar LazySSH."
    RESULTS[lazyssh]="Error"
    return 1
  fi

  if ! brew_has_binary lazyssh; then
    error "El instalador terminó pero 'lazyssh' no se encontró en $(brew_bin_dir)."
    RESULTS[lazyssh]="Error"
    return 1
  fi
  success "LazySSH instalado correctamente."
  RESULTS[lazyssh]="Éxito"
}


check_lazyssh() {
  cmd_available lazyssh && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
