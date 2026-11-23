#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 9. Brave Browser
install_brave() {
  header "Instalando Brave Browser"
  if [ "$DISTRO" = "cachyos" ]; then
    # CachyOS trae chaotic-aur por defecto con 'brave-bin' precompilado
    # (también en el repo propio cachyos): no hace falta helper AUR.
    # Nota: el paquete de repo puede ir alguna versión por detrás del upstream.
    if install_package brave-bin; then
      info "Brave instalado desde los repositorios (brave-bin)."
    else
      warn "No se pudo instalar brave-bin desde los repos; probando el instalador oficial..."
      # -o pipefail: sin él, un curl fallido deja a sh sin entrada y devuelve 0.
      if ! bash -o pipefail -c 'curl -fsS https://dl.brave.com/install.sh | sh'; then
        error "Error al instalar Brave Browser."
        RESULTS[brave]="Error"
        return 1
      fi
    fi
  else
    # Fedora: el instalador oficial configura el repo dnf de Brave.
    # -o pipefail: sin él, un curl fallido deja a sh sin entrada y devuelve 0.
    if ! bash -o pipefail -c 'curl -fsS https://dl.brave.com/install.sh | sh'; then
      error "Error al instalar Brave Browser."
      RESULTS[brave]="Error"
      return 1
    fi
  fi
  # brave-bin puede exponer 'brave' en vez de 'brave-browser': se acepta
  # cualquiera de los dos (patrón yazi/lazygit/antigravity: sin binario no hay Éxito).
  if command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; then
    success "Brave Browser instalado correctamente."
    RESULTS[brave]="Éxito"
  else
    error "El instalador terminó pero no se encontró 'brave-browser' ni 'brave'."
    RESULTS[brave]="Error"
    return 1
  fi
}


check_brave() {
  # brave-bin puede exponer 'brave' en vez de 'brave-browser' (ver install_brave).
  { command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
