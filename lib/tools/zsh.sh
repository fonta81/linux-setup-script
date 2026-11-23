#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 3. Instalar Zsh y Oh My Zsh
install_zsh_ohmyzsh() {
  header "Instalando Zsh y Oh My Zsh"
  info "Instalando Zsh..."
  if ! install_package zsh; then
    error "Error al instalar Zsh."
    RESULTS[zsh]="Error"
    return 1
  fi

  if command -v chsh >/dev/null 2>&1; then
    info "Cambiando la shell predeterminada de $REAL_USER a Zsh..."
    local zsh_bin
    zsh_bin=$(command -v zsh 2>/dev/null)
    # chsh falla (y no avisa) si zsh no está en /etc/shells: nodea el error
    if [ -n "$zsh_bin" ] && chsh -s "$zsh_bin" "$REAL_USER"; then
      success "Shell predeterminada de $REAL_USER: $zsh_bin"
    else
      warn "chsh no pudo cambiar la shell de $REAL_USER (probable: zsh no está en /etc/shells)."
      warn "Cámbiala a mano con: chsh -s \$(command -v zsh) $REAL_USER"
    fi
  else
    warn "No se pudo encontrar 'chsh'. Por favor cambia tu shell manualmente a Zsh usando: chsh -s \$(command -v zsh)"
  fi

  if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh ya parece estar instalado en $REAL_HOME/.oh-my-zsh."
    RESULTS[zsh]="Éxito (Ya existía)"
  else
    info "Instalando Oh My Zsh en modo unattended..."
    # curl primero a una variable: si falla, sh sin entrada daría un falso Éxito.
    # Se canaliza por pipe a 'sh -s' en vez de 'sh -c "$var"' (quoting/ARG_MAX).
    local omz_installer
    if ! omz_installer=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) ||
      [ -z "$omz_installer" ]; then
      error "No se pudo descargar el instalador de Oh My Zsh."
      RESULTS[zsh]="Error"
      return 1
    fi
    if printf '%s\n' "$omz_installer" | run_as_user env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -s -- --unattended; then
      success "Oh My Zsh instalado de manera exitosa."
      RESULTS[zsh]="Éxito"
    else
      error "Error durante la instalación de Oh My Zsh."
      RESULTS[zsh]="Error"
      return 1
    fi
  fi
}


check_zsh() {
  if command -v zsh >/dev/null 2>&1 && [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}Instalado (con Oh My Zsh)${NC}"
  elif command -v zsh >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Zsh (sin Oh My Zsh)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
