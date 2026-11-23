#!/usr/bin/env bash
# Funciones de configuración y verificación de la herramienta.


# 16. Configurar .zshrc personalizado y Ghostty
configure_zshrc() {
  header "Configurando archivo .zshrc personalizado y Ghostty"
  local zshrc_dir
  case "$DISTRO" in
  fedora) zshrc_dir="$SCRIPT_DIR/config_zsh/Fedora" ;;
  cachyos) zshrc_dir="$SCRIPT_DIR/config_zsh/Cachyos" ;;
  *)
    error "Distribución desconocida ($DISTRO): no se qué .zshrc instalar."
    RESULTS[zshrc]="Error"
    return 1
    ;;
  esac
  local source_zshrc="$zshrc_dir/.zshrc"
  if [ -f "$source_zshrc" ]; then
    if [ -f "$REAL_HOME/.zshrc" ]; then
      local backup_zshrc="$REAL_HOME/.zshrc.bak.$(date +%F_%H-%M-%S)"
      info "Se detectó un archivo .zshrc existente. Creando respaldo en $backup_zshrc..."
      if run_as_user cp "$REAL_HOME/.zshrc" "$backup_zshrc"; then
        success "Respaldo creado."
      else
        warn "No se pudo crear el respaldo de .zshrc. Continuando..."
      fi
    fi

    info "Instalando el archivo .zshrc personalizado en $REAL_HOME..."
    if run_as_user cp "$source_zshrc" "$REAL_HOME/.zshrc"; then
      success ".zshrc configurado de manera exitosa."
    else
      error "Error al copiar el archivo .zshrc a $REAL_HOME."
      RESULTS[zshrc]="Error"
      return 1
    fi
  else
    error "No se encontró el archivo .zshrc de origen en $source_zshrc."
    RESULTS[zshrc]="Error"
    return 1
  fi

  local source_ghostty="$SCRIPT_DIR/config_ghostty/config"
  if [ -f "$source_ghostty" ]; then
    info "Instalando configuración de Ghostty en $REAL_HOME/.config/ghostty/..."
    run_as_user mkdir -p "$REAL_HOME/.config/ghostty"
    backup_if_exists "$REAL_HOME/.config/ghostty/config"
    if run_as_user cp -r "$source_ghostty" "$REAL_HOME/.config/ghostty/"; then
      success "Configuración de Ghostty instalada."
    else
      warn "No se pudo instalar la configuración de Ghostty. Continuando..."
    fi
  else
    warn "No se encontró el config de Ghostty en $source_ghostty. Omitiendo..."
  fi

  RESULTS[zshrc]="Éxito"
}


check_zshrc() {
  local has_zshrc="no"
  local has_ghostty="no"
  [ -f "$REAL_HOME/.zshrc" ] && has_zshrc="si"
  [ -f "$REAL_HOME/.config/ghostty/config" ] && has_ghostty="si"

  if [ "$has_zshrc" = "si" ] && [ "$has_ghostty" = "si" ]; then
    echo -e "${GREEN}Configurado${NC}"
  elif [ "$has_zshrc" = "si" ]; then
    if grep -q "pokemon-colorscripts" "$REAL_HOME/.zshrc" 2>/dev/null; then
      echo -e "${YELLOW}Configurado (sin Ghostty)${NC}"
    else
      echo -e "${YELLOW}Por defecto (sin personalización)${NC}"
    fi
  else
    echo -e "${RED}No instalado/configurado${NC}"
  fi
}
