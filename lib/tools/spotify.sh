#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 10. Spotify
install_spotify() {
  install_flatpak_app "spotify" "com.spotify.Client" "Spotify"
}


check_spotify() {
  # list como el usuario real: como root no se ven las apps --user.
  if check_flatpak_app_installed "com.spotify.Client"; then
    echo -e "${GREEN}Instalado (Flatpak)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
