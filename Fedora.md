# Fedora

# Notas manuales; el script manda (ver README).

## Parte #1

sudo dnf upgrade --refresh -y

### Flatpak

cd
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### zsh && ohmyzsh

cd
sudo dnf install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### yazi

cd
sudo dnf copr enable -y lihaohong/yazi
sudo dnf install -y yazi

### nvim && lazyvim

cd
sudo dnf install -y neovim git ripgrep fd-find fzf gcc make unzip
git clone https://github.com/LazyVim/starter ~/.config/nvim

### lazygit

cd
sudo dnf install -y --nogpgcheck --repofrompath "terra-fyralabs,https://repos.fyralabs.com/terra$releasever" terra-release
sudo dnf install -y lazygit

### pokemonscripts(terminal)

cd
git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh

### gemini-copilot

cd
sudo dnf install -y nodejs npm
mkdir -p ~/.npm-global
npm config set prefix "$HOME/.npm-global"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc

npm install -g @google/gemini-cli

### Brave

cd
curl -fsS https://dl.brave.com/install.sh | sh

### Spotify

cd
flatpak install --user -y flathub com.spotify.Client

### Obsidian

cd
flatpak install --user -y flathub md.obsidian.Obsidian

## Parte #2(Opcional)

## Dank Material Shell

# (interactivo: te pregunta compositor -niri/hyprland- y terminal -ghostty/kitty/alacritty-;
#  como tu usuario, nunca root)
curl -fsSL https://install.danklinux.com | sh

## My configs

# (pide confirmación [s/N] si ya existe config, y respalda la existente;
#  conserva el .git para futuros git pull)

[ -e ~/.config/niri ] && mv ~/.config/niri ~/.config/niri.bak-$(date +%s)
git clone https://github.com/fonta81/.BackNiriDank.git ~/.config/niri

## Config plugins ohmyzsh

# (OMZ exige custom/plugins/<nombre>/<nombre>.plugin.zsh: un symlink al
#  directorio del sistema da 'plugin not found'. Se crea un puente .plugin.zsh
#  que hace source al .zsh del paquete.)
sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo '[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
echo '[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
# si tu plugins=( es multilinea, anade los plugins a mano
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc

## conf .zshrc && ghostty

# (respalda tu .zshrc antes; este paso lo sobrescribe y va al final)
cp ./config_zsh/Fedora/.zshrc ~/.zshrc
mkdir -p ~/.config/ghostty
cp ./config_ghostty/config ~/.config/ghostty/
