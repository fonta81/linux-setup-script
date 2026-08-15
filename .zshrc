# oh-my-zsh:
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
# Fin oh-my-zsh

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

# Pokemon:
pokemon-colorscripts -r --no-title
# Fin Pokemon:



# Alias: 
alias c="clear"
alias cc="clear && pokemon-colorscripts -r --no-title"
alias y="yazi"
alias gg="lazygit"
alias nir="cd ~/.config/niri/"
alias nz="nvim ~/.zshrc"
alias n="nvim"
alias pk="pokemon-colorscripts -r --no-title"
alias pkk="pokemon-colorscripts -n"
alias update="sudo dnf upgrade --refresh"
# Fin Alias

autoload -Uz compinit
compinit
# End of lines added by compinstall

# npm-global:
export PATH=~/.npm-global/bin:$PATH
# fin npm-global

# EditorRCodigoPredeterminado
export EDITOR="nvim"
export VISUAL="nvim"
# Fin EditorRCodigoPredeterminado

# Plugins extra (zsh-autosuggestions / zsh-syntax-highlighting).
# Se cargan aquí en vez de vía plugins=() porque install_zsh_plugins() los
# instala en un paso opcional aparte; el chequeo -f evita un error de zsh
# si aún no se instalaron.
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Fin Plugins extra

