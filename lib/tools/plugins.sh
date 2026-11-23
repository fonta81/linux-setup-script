#!/usr/bin/env bash
# Funciones de configuración y verificación de la herramienta.


# 15. Plugins Oh My Zsh
install_zsh_plugins() {
  header "Configurando Plugins de Oh My Zsh"
  if ! install_package zsh-autosuggestions zsh-syntax-highlighting; then
    error "Error al instalar paquetes de plugins."
    RESULTS[plugins]="Error"
    return 1
  fi

  # Rutas de origen según distro (scripts .zsh provistos por el paquete)
  if [ "$DISTRO" = "fedora" ]; then
    local src_auto="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    local src_syntax="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  else
    local src_auto="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    local src_syntax="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi

  local custom_plugins_dir="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  run_as_user mkdir -p "$custom_plugins_dir"
  # OMZ solo carga custom/plugins/<nombre>/<nombre>.plugin.zsh: el symlink
  # al directorio del sistema nunca cargaba ('plugin not found' en Fedora).
  # Se crea un bridge que hace source al .zsh del paquete.
  local plugin src_file plug_dir bridge
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    case "$plugin" in
    zsh-autosuggestions) src_file="$src_auto" ;;
    zsh-syntax-highlighting) src_file="$src_syntax" ;;
    esac
    if [ ! -f "$src_file" ]; then
      warn "No se encontró $src_file: el plugin $plugin quedará sin fuente."
      continue
    fi
    plug_dir="$custom_plugins_dir/$plugin"
    bridge="$plug_dir/$plugin.plugin.zsh"
    # Si existía el symlink antiguo al directorio, se reemplaza por el bridge.
    if [ -L "$plug_dir" ]; then
      run_as_user rm -f "$plug_dir"
    fi
    # No pisar un bridge/clon ajeno (p. ej. clon git del upstream con su
    # propio .plugin.zsh): solo se escribe si falta o si lo generamos antes.
    if run_as_user test -f "$bridge" 2>/dev/null &&
      ! run_as_user grep -q "Generado por linux-setup-script" "$bridge" 2>/dev/null; then
      warn "Se conserva el $bridge existente (no lo generó este script)."
      continue
    fi
    run_as_user mkdir -p "$plug_dir"
    run_as_user bash -c "printf '%s\n' '# Generado por linux-setup-script: puente al paquete del sistema.' '[ -f \"$src_file\" ] && source \"$src_file\"' > '$bridge'"
    info "Plugin $plugin disponible vía $bridge."
  done

  local zshrc="$REAL_HOME/.zshrc"
  [ -f "$zshrc" ] || run_as_user touch "$zshrc"

  # El grep debe reconocer tanto una lista de una línea como un bloque multilínea,
  # y el sed solo sirve en el primer caso: antes se anunciaba un "añadido" que
  # no ocurría cuando plugins=( está en su propia línea.
  # El carácter tras el nombre puede ser espacio, salto de línea o ')'.
  local plugin
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if run_as_user grep -qE "(^|[[:space:]])${plugin}([[:space:])]|$)" "$zshrc"; then
      info "Plugin $plugin ya estaba en .zshrc."
    elif run_as_user grep -qE '^plugins=\([[:space:]]*$' "$zshrc"; then
      info "La lista plugins=( de $zshrc es multilínea: no se modifica automáticamente."
      info "  Añade $plugin a mano si hace falta (el paso 'Configuración .zshrc' sobrescribe el archivo)."
    elif run_as_user grep -q '^plugins=([^)]*)' "$zshrc"; then
      if run_as_user sed -i "s/^plugins=(\([^)]*\))/plugins=(\1 $plugin)/" "$zshrc" &&
        run_as_user grep -qE "(^|[[:space:]])${plugin}([[:space:])]|$)" "$zshrc"; then
        info "Plugin $plugin añadido a .zshrc."
      else
        warn "No se pudo añadir $plugin a la lista plugins=( de $zshrc."
      fi
    else
      info "No se encontró una línea 'plugins=(...)' en $zshrc: se deja sin tocar."
      info "  Añade $plugin a mano si hace falta (el paso 'Configuración .zshrc' sobrescribe el archivo)."
    fi
  done
  success "Plugins de Oh My Zsh configurados."
  RESULTS[plugins]="Éxito"
}


check_plugins() {
  local base="${ZSH_CUSTOM:-$REAL_HOME/.oh-my-zsh/custom}/plugins"
  if [ -f "$base/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ] &&
    [ -f "$base/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ]; then
    echo -e "${GREEN}Configurado${NC}"
  else
    echo -e "${RED}No${NC}"
  fi
}
