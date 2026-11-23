#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 11. Obsidian
install_obsidian() {
  install_flatpak_app "obsidian" "md.obsidian.Obsidian" "Obsidian"
}


check_obsidian() {
  if check_flatpak_app_installed "md.obsidian.Obsidian"; then
    echo -e "${GREEN}Instalado (Flatpak)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
