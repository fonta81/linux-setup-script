#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 7. Pokemon Colorscripts
install_pokemon_colorscripts() {
  header "Instalando Pokemon Colorscripts"
  # mktemp -d evita el /tmp con nombre fijo, que otro usuario podría crear antes
  local temp_dir
  temp_dir=$(make_tempdir /tmp/pokemon-colorscripts.XXXXXX) || {
    error "No se pudo crear el directorio temporal."
    RESULTS[pokemon]="Error"
    return 1
  }
  info "Clonando repositorio..."
  if ! run_as_user git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$temp_dir/repo"; then
    error "Error al clonar el repositorio de pokemon-colorscripts."
    RESULTS[pokemon]="Error"
    rm -rf "$temp_dir"
    return 1
  fi
  # install.sh copia a /usr/local/opt y symlinkea en /usr/local/bin: necesita root
  if (cd "$temp_dir/repo" && ./install.sh); then
    success "Pokemon Colorscripts instalado correctamente."
    RESULTS[pokemon]="Éxito"
  else
    error "Error al instalar Pokemon Colorscripts."
    RESULTS[pokemon]="Error"
    rm -rf "$temp_dir"
    return 1
  fi
  rm -rf "$temp_dir"
}


check_pokemon() {
  { command -v pokemon-colorscripts >/dev/null 2>&1 || [ -f "/usr/local/bin/pokemon-colorscripts" ]; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
