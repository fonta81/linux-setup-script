# Automated Linux Development Environment Bootstrapper

This repository contains personal, interactive, menu-driven Bash automation scripts and configuration profiles designed to bootstrap a complete developer environment on modern Linux distributions: **Fedora** and **CachyOS** (an Arch Linux derivative).

## Key Features & Tools Installed

The scripts automate the setup of fifteen (15) core system features and tools:

### Category 1: CLI Utilities, Shells & Editors
1. **System Upgrade**: Refreshes repositories and performs upgrades.
2. **Flatpak & Flathub**: Sets up and registers the Flathub remote repository.
3. **Zsh & Oh My Zsh**: Safely switches default shell and installs `oh-my-zsh` (unattended).
4. **Yazi**: Fast terminal file manager.
5. **Neovim & LazyVim**: Modern extensible text editor and starter template.
6. **Lazygit**: Git terminal client.
7. **Pokemon Colorscripts**: CLI Pokémon sprites viewer.
8. **Gemini Copilot**: Local Node.js global environment and `@google/gemini-cli`.
9. **Zsh Plugins**: `zsh-autosuggestions` and `zsh-syntax-highlighting` installation and integration.
10. **Custom `.zshrc`**: Deploys a fully-configured Zsh profile with custom aliases and tools.

### Category 2: GUI Apps & Custom Desktop Configurations
11. **Brave Browser**: Secure browser installation.
12. **Spotify**: Music player deployed via Flatpak.
13. **Obsidian**: Knowledge base application deployed via Flatpak.
14. **Dank Material Shell**: Automated install script for custom layout and theme engines.
15. **Niri Configuration Files**: Clones custom desktop configs into `~/.config/niri`.

---

## Usage

Run the appropriate script using `sudo` depending on your Linux distribution:

### For Fedora Systems
```bash
sudo ./Fedora.sh
```

### For CachyOS (Arch) Systems
```bash
sudo ./Cachyos.sh
```

### Execution Modes
When running either script, you can choose from:
1. **Todo automático (All Automatic):** Sequentially executes all 15 configuration steps without pausing.
2. **Interactivo (Interactive Selection):** Prompts for `[y/N]` confirmation before executing each step.
3. **Estado (Check Status):** Displays a clean CLI status table identifying which tools are already present on the system.
4. **Salir (Exit):** Clean exit.

---

## Languages

Read this documentation in:
- [Spanish](README.es.md)
