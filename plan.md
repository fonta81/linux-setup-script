# Fedora:

## Parte #1:
sudo dnf upgrade --refresh

### Flatpak
cd
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### zsh && ohmyzsh:
cd
dnf install zsh 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### yazi:
cd
dnf copr enable lihaohong/yazi
dnf install yazi

### nvim && lazyvim:
cd
dnf install nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

### lazygit:
cd
sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit -y

### pokemonscripts(terminal):
cd
git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh

### gemini-copilot:
cd
dnf install npm nodejs
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc

npm install -g @google/gemini-cli

### Brave:
cd
curl -fsS https://dl.brave.com/install.sh | sh

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
git clone git@github.com:fonta81/.BackNiriDank.git ~/.config/niri/.BackNiriDank
rm -rf ~/.config/niri && mv ~/.config/.BackNiriDank ~/.confg/niri

## Config plugins ohmyzsh:

sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting
mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins
ln -snf /usr/share/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
ln -snf /usr/share/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc

## conf .zshrc

mv ./.zshrc ~/


