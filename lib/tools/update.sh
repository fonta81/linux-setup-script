#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# --- Funciones de Instalación Unificadas ----------------------------------

# 1. Actualizar el sistema
install_update() {
  header "Actualizando el sistema $DISTRO"
  if run_on_distro "dnf upgrade --refresh -y" "pacman -Syu --noconfirm"; then
    success "Sistema actualizado correctamente."
    RESULTS[update]="Éxito"
  else
    error "Error al actualizar el sistema."
    RESULTS[update]="Error"
    return 1
  fi
}


# --- Funciones de Verificación Unificadas ---------------------------------

check_update() {
  # Placeholder honesto: este paso siempre está disponible bajo demanda,
  # no hay un estado "actualizado" barato de verificar sin correr el upgrade.
  echo -e "${BLUE}Bajo demanda${NC}"
}
