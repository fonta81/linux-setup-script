#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 4. Instalar Yazi
install_yazi() {
  header "Instalando Yazi (File Manager de Terminal)"
  # Dependencia: si el paso 'brew' fue omitido, se instala aquí como efecto
  # secundario (con un aviso), sin tocar RESULTS[brew].
  if ! ensure_brew; then
    error "Sin Homebrew no se puede instalar Yazi."
    RESULTS[yazi]="Error"
    return 1
  fi

  info "Instalando yazi con Homebrew..."
  if ! brew_install yazi; then
    error "Error al instalar Yazi."
    RESULTS[yazi]="Error"
    return 1
  fi
  # Verificación: nunca reportar Éxito sin el binario (patrón lavat/antigravity).
  # brew_has_binary mira el prefijo de brew, fuera del PATH de root, y a
  # diferencia de cmd_available no acepta un yazi viejo de pacman como válido.
  if ! brew_has_binary yazi; then
    error "El instalador terminó pero 'yazi' no se encontró en $(brew_bin_dir)."
    RESULTS[yazi]="Error"
    return 1
  fi
  success "Yazi instalado correctamente."
  RESULTS[yazi]="Éxito"
}


check_yazi() {
  # 'Instalado' aquí significa 'la herramienta está disponible para el usuario',
  # venga de Homebrew, del PATH del sistema o de ~/.local/bin; para exigir la
  # fórmula de brew (verificación tras instalar) está brew_has_binary.
  cmd_available yazi && echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
