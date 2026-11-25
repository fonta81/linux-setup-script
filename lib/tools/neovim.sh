#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 5. Neovim y LazyVim
# ------------------------------------------------------------------------------
# install_neovim_lazyvim
# Installs Neovim and the runtime dependencies LazyVim needs (git, ripgrep, fd,
# fzf, gcc, make, unzip), then deploys the LazyVim starter template as
# $REAL_HOME/.config/nvim.
#
# Notes:
#   - The fd package is named `fd-find` on Fedora and `fd` on CachyOS; both
#     provide the `fd` binary that telescope uses.
#   - fzf, gcc, make and unzip are required by treesitter and other plugins.
#   - The config is deployed atomically by deploy_clone, keeping its .git so the
#     resulting directory can be updated with `git pull` later.
#   - Sets RESULTS[neovim] to "Éxito" or "Error" and returns 1 on failure.
# ------------------------------------------------------------------------------
install_neovim_lazyvim() {
  header "Instalando Neovim, LazyVim y Dependencias"
  local fd_package="fd"
  if [ "$DISTRO" = "fedora" ]; then
    fd_package="fd-find"
  fi

  info "Instalando Neovim, git, ripgrep, $fd_package y dependencias de LazyVim (fzf, gcc, make, unzip)..."
  if ! install_package neovim git ripgrep "$fd_package" fzf gcc make unzip; then
    error "Error al instalar Neovim o sus dependencias básicas."
    RESULTS[neovim]="Error"
    return 1
  fi

  if [ "$DISTRO" = "fedora" ]; then
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


# ------------------------------------------------------------------------------
# check_neovim
# Prints the Neovim status shown in the status table: installed with LazyVim
# (nvim on PATH and the nvim config directory present), Neovim alone, or not
# installed. Read-only: it does not touch RESULTS.
# ------------------------------------------------------------------------------
check_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ -d "$REAL_HOME/.config/nvim" ]; then
    echo -e "${GREEN}Instalado (con LazyVim)${NC}"
  elif command -v nvim >/dev/null 2>&1; then
    echo -e "${YELLOW}Solo Neovim (sin LazyVim)${NC}"
  else
    echo -e "${RED}No instalado${NC}"
  fi
}
