#!/usr/bin/env bash
# Funciones de instalación y verificación de la herramienta.


# 9. Gemini Copilot
install_gemini_copilot() {
  header "Instalando Gemini Copilot (gemini-cli)"
  # Dependencia: si el paso 'node' fue omitido, se instala aquí como efecto
  # secundario. No se toca RESULTS[node] porque el usuario no aceptó ese paso.
  if ! ensure_node_for "Gemini"; then
    error "Sin Node.js/npm no se puede instalar gemini-cli."
    RESULTS[gemini]="Error"
    return 1
  fi

  info "Instalando @google/gemini-cli globalmente..."
  if npm_install_global "@google/gemini-cli" "gemini"; then
    success "Gemini Copilot se ha instalado correctamente."
    warn "Nota: Recuerda reiniciar la terminal o ejecutar 'source ~/.zshrc' para poder usar el comando 'gemini'."
    RESULTS[gemini]="Éxito"
  else
    RESULTS[gemini]="Error"
    return 1
  fi
}


check_gemini() {
  { [ -f "$REAL_HOME/.npm-global/bin/gemini" ] || command -v gemini >/dev/null 2>&1; } &&
    echo -e "${GREEN}Instalado${NC}" || echo -e "${RED}No instalado${NC}"
}
