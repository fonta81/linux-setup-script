# CachyOS:

# Notas manuales; el script manda (ver README).

## Parte #1:
sudo pacman -Syu

### Flatpak
cd
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### zsh && ohmyzsh:
cd
sudo pacman -S --noconfirm zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Note: Paths for plugins in Arch differ from Fedora
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### yazi:
cd
sudo pacman -S --noconfirm yazi

### nvim && lazyvim:
cd
sudo pacman -S --noconfirm neovim git ripgrep fd
git clone https://github.com/LazyVim/starter ~/.config/nvim

### lazygit:
cd
sudo pacman -S --noconfirm lazygit

### pokemonscripts(terminal):
cd
git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh

### gemini-copilot:
cd
sudo pacman -S --noconfirm nodejs npm
mkdir -p ~/.npm-global
npm config set prefix "$HOME/.npm-global"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc

npm install -g @google/gemini-cli

### Brave:
cd
curl -fsS https://dl.brave.com/install.sh | sh

### Spotify:
cd
flatpak install --user -y flathub com.spotify.Client

### Obsidian:
cd
flatpak install --user -y flathub md.obsidian.Obsidian

## Parte #2(Opcional):

## Dank Material Shell:
# (interactivo: te pregunta compositor -niri/hyprland- y terminal -ghostty/kitty/alacritty-;
#  como tu usuario, nunca root)
curl -fsSL https://install.danklinux.com | sh


## My configs:
# (el script pide confirmación [s/N] si ya existe config, respalda la
#  existente y conserva el .git para futuros git pull)
[ -e ~/.config/niri ] && mv ~/.config/niri ~/.config/niri.bak-$(date +%s)
git clone https://github.com/fonta81/.BackNiriDank.git ~/.config/niri

## Config plugins ohmyzsh:

# (OMZ exige custom/plugins/<nombre>/<nombre>.plugin.zsh: un symlink al
#  directorio del sistema da 'plugin not found'. Se crea un puente .plugin.zsh
#  que hace source al .zsh del paquete.)
sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo '[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
echo '[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
# si tu plugins=( es multilinea, anade los plugins a mano
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc

## conf .zshrc && ghostty

# (respalda tu .zshrc antes; este paso lo sobrescribe y va al final)
cp ./config_zsh/Cachyos/.zshrc ~/.zshrc
mkdir -p ~/.config/ghostty
cp ./config_ghostty/config ~/.config/ghostty/
