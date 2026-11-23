#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 5. Neovim y LazyVim
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  if [ "$DISTRO" = "fedora" ]; then
    info "Instalando Neovim, git, ripgrep, fd-find y dependencias de LazyVim (fzf, gcc, make, unzip)..."
    if ! install_package neovim git ripgrep fd-find fzf gcc make unzip; then
      error "Error al instalar Neovim o sus dependencias básicas."
      RESULTS[neovim]="Error"
      return 1
    fi
    # El paquete Fedora 'fd-find' ya provee el binario 'fd' (el nombre
    # 'fdfind' es propio de Debian); el enlace solo hace falta si aparece
    # 'fdfind' sin que haya un 'fd' visible para el usuario real.
    # El enlace vive en su ~/.local/bin (que el .zshrc añade al PATH al final,
    # así que solo se verifica el archivo, no 'command -v', en esta sesión).
    if [ ! -e "$REAL_HOME/.local/bin/fd" ] && ! run_as_user bash -c 'command -v fd' >/dev/null 2>&1; then
      local fdfind_path
      fdfind_path=$(run_as_user bash -c 'command -v fdfind' 2>/dev/null)
      if [ -n "$fdfind_path" ]; then
        run_as_user mkdir -p "$REAL_HOME/.local/bin"
        if run_as_user ln -snf "$fdfind_path" "$REAL_HOME/.local/bin/fd"; then
          info "Creado enlace ~/.local/bin/fd -> $fdfind_path para las herramientas de Neovim."
          info "Estará en el PATH tras aplicar el paso 'Configuración .zshrc' y reabrir la terminal."
        fi
      fi
    fi
  else
    info "Instalando Neovim, git, ripgrep, fd y dependencias de LazyVim (fzf, gcc, make, unzip)..."
    # En Arch/CachyOS los paquetes son 'ripgrep' y 'fd' (binarios rg y fd),
    # que necesita LazyVim/telescope. Sin ellos el paso parecía correcto pero
    # el editor fallaba al usar la búsqueda de archivos. gcc/make/unzip/fzf
    # los exigen treesitter y otros plugins (igual que en Fedora).
    if ! install_package neovim git ripgrep fd fzf gcc make unzip; then
      error "Error al instalar Neovim o sus dependencias básicas."
      RESULTS[neovim]="Error"
      return 1
    fi
  fi

  info "Clonando la plantilla starter de LazyVim..."
  if deploy_clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"; then
    success "Neovim y LazyVim configurados de manera exitosa."
    RESULTS[neovim]="Éxito"
  else
    error "Error al configurar Neovim/LazyVim${DEPLOY_BACKUP:+ (respaldo previo en $DEPLOY_BACKUP)}."
    RESULTS[neovim]="Error"
    return 1
  fi
}


check_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ -d "$REAL_HOME/.config/nvim" ]; then
    echo -e "${GREEN}Instalado (con LazyVim)${NC}"
  elif command -v nvim >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Neovim (sin LazyVim)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
