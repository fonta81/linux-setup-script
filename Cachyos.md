# CachyOS:

## Parte #1:
sudo pacman -Syu

### Flatpak
cd
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### zsh && ohmyzsh:
cd
sudo pacman -S zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Note: Paths for plugins in Arch differ from Fedora
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### yazi:
cd
sudo pacman -S yazi

### nvim && lazyvim:
cd
sudo pacman -S neovim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

### lazygit:
cd
sudo pacman -S lazygit

### pokemonscripts(terminal):
cd
git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh

### gemini-copilot:
cd
sudo pacman -S npm nodejs
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc

npm install -g @google/gemini-cli

### Brave:
cd
sudo pacman -S brave-browser

### Spotify:
cd
flatpak install flathub com.spotify.Client

### Obsidian:
cd
flatpak install flathub md.obsidian.Obsidian

## Parte #2(Opcional):

## Dank Material Shell:
curl -fsSL https://install.danklinux.com | sh


## My configs:
# (respalda la config existente si la hay, en vez de borrarla)
[ -e ~/.config/niri ] && mv ~/.config/niri ~/.config/niri.bak-$(date +%s)
git clone git@github.com:fonta81/.BackNiriDank.git ~/.config/niri
rm -rf ~/.config/niri/.git

## Config plugins ohmyzsh:

sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins
ln -snf /usr/share/zsh/plugins/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
ln -snf /usr/share/zsh/plugins/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc

## conf .zshrc

mv ./.zshrc ~/
