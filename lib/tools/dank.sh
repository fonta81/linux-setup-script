#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 12. Dank Shell
# Detección compartida de DMS: sirve para el skip, para check_dank y para verificar tras instalar
dms_installed() {
  command -v dms >/dev/null 2>&1 || [ -x "$REAL_HOME/.local/bin/dms" ]
}


install_dank_shell() {
  header "Instalando Dank Material Shell"

  if dms_installed; then
    warn "Dank Material Shell ya está instalado. Se omite; usa 'dms' para reconfigurar o actualizar."
    RESULTS[dank]="Éxito (Ya existía)"
    return 0
  fi

  if [ "$REAL_USER" = "root" ]; then
    error "dankinstall se niega a ejecutarse como root y no hay un usuario real detectado."
    RESULTS[dank]="Error"
    return 1
  fi

  info "Se abrirá el instalador interactivo de Dank. Responde sus preguntas (compositor: niri/hyprland, terminal: ghostty/kitty, etc.)."
  info "Se ejecuta como $REAL_USER; si pide una contraseña de sudo, es la tuya."

  # -o pipefail es imprescindible: sin él, un curl fallido (red/404) devolvería 0
  if ! run_as_user bash -o pipefail -c 'curl -fsSL https://install.danklinux.com | sh'; then
    error "Error al instalar Dank Material Shell."
    warn "Revisa los logs del instalador en /tmp/dankinstall-*.log"
    RESULTS[dank]="Error"
    return 1
  fi

  if ! dms_installed; then
    error "El instalador terminó pero 'dms' no se encontró en el sistema."
    warn "Revisa los logs del instalador en /tmp/dankinstall-*.log"
    RESULTS[dank]="Error"
    return 1
  fi

  success "Dank Material Shell instalado correctamente."
  RESULTS[dank]="Éxito"
}


check_dank() {
  if dms_installed; then
    echo -e "${GREEN}Instalado${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
