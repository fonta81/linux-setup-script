#!/usr/bin/env bash
# Funciones de configuración y verificación de la herramienta.


check_dir_exists() {
  [ -d "$1" ] && echo -e "${GREEN}Configurado${NC}" || echo -e "${RED}No${NC}"
}


# 13. Configs Niri
install_configs() {
  header "Aplicando configuraciones personales"
  # Este paso reemplaza ~/.config/niri, incluida la que acababa de generar
  # dankinstall: se pide confirmación si ya existe algo.
  if [ -e "$REAL_HOME/.config/niri" ]; then
    warn "Esto reemplazará tu ~/.config/niri actual (se guardará un respaldo .bak-<epoch>)."
    echo -en "¿Continuar y reemplazar la config de Niri? [s/N]: "
    local ans
    read -r ans
    if [[ ! "$ans" =~ ^[sS]$ ]]; then
      info "Paso de Niri omitido por el usuario."
      RESULTS[configs]="Omitido"
      return 0
    fi
  fi
  if deploy_clone https://github.com/fonta81/.BackNiriDank.git "$REAL_HOME/.config/niri"; then
    success "Configuraciones aplicadas correctamente."
    RESULTS[configs]="Éxito"
  else
    error "Error al aplicar configuraciones personales${DEPLOY_BACKUP:+ (respaldo previo en $DEPLOY_BACKUP)}."
    RESULTS[configs]="Error"
    return 1
  fi
}


check_configs() {
  check_dir_exists "$REAL_HOME/.config/niri"
}
