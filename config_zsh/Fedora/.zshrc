# ==========================================
# 1. INSTALACIÓN DE PAQUETES DE SISTEMA
# ==========================================
# (En un sistema sin Home Manager, debes instalar manualmente los paquetes):
# nix-env -iA nixpkgs.pokemon-colorscripts nixpkgs.yazi
# O con el gestor de paquetes de tu distro (ej. sudo pacman -S yazi)


# ==========================================
# 2. VARIABLES DE ENTORNO Y PATH
# ==========================================
export EDITOR="nvim"
export VISUAL="nvim"

# Agregar directorio global de NPM al PATH de forma segura
if [[ ! ":$PATH:" == *":$HOME/.npm-global/bin:"* ]]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi


# ==========================================
# 3. CONFIGURACIÓN DEL HISTORIAL
# ==========================================
HISTFILE="$HOME/.histfile"
HISTSIZE=1000
SAVEHIST=1000


# ==========================================
# 4. OH MY ZSH Y PLUGINS
# ==========================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Habilitar autocompletado avanzado de Zsh
autoload -U compinit && compinit

# Plugins de Oh My Zsh (asegúrate de tener clonados zsh-autosuggestions y zsh-syntax-highlighting)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Cargar Oh My Zsh
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi


# ==========================================
# 5. ALIASES
# ==========================================

# clear 
alias c="clear"
alias cc="clear && pokemon-colorscripts -r --no-title"

# aplicaciones
alias y="yazi"
alias gg="lazygit"
alias n="nvim"

# pokemon
alias pk="pokemon-colorscripts -r --no-title"
alias pkk="clear && pokemon-colorscripts --no-title -n "
alias pkkex="clear && pokemon-colorscripts --no-title -n excadrill"
alias pkkgen="clear && pokemon-colorscripts --no-title -n gengar"

# niri
alias nir="cd ~/.config/niri/"

# zsh
alias nz="nvim ~/.zshrc"

# Fedora
alias update="sudo dnf upgrade --refresh"

# ==========================================
# 6. INICIALIZACIÓN / STARTUP (initContent)
# ==========================================
# Muestra un pokémon aleatorio al abrir la terminal
if command -v pokemon-colorscripts &> /dev/null; then
  pokemon-colorscripts -r --no-title
fi


# Added by Antigravity CLI installer
export PATH="/home/mteo/.local/bin:$PATH"
