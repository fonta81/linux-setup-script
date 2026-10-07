# Automated Linux Development Environment Bootstrapper

This repository contains personal, interactive, menu-driven Bash automation scripts and configuration profiles designed to bootstrap a complete developer environment on modern Linux distributions: **Fedora** and **CachyOS** (an Arch Linux derivative).

## Key Features & Tools Installed

The scripts automate the setup of sixteen (16) core system features and tools, listed in the exact order they appear in the menu and status table:

1. **System Upgrade**: Refreshes repositories and performs upgrades.
2. **Flatpak & Flathub**: Sets up and registers the Flathub remote repository.
3. **Zsh & Oh My Zsh**: Safely switches default shell and installs `oh-my-zsh` (unattended).
4. **Yazi**: Fast terminal file manager.
5. **Neovim & LazyVim**: Modern extensible text editor and starter template.
6. **Lazygit**: Git terminal client.
7. **Pokemon Colorscripts**: CLI Pokémon sprites viewer.
8. **Gemini Copilot**: Local Node.js global environment and `@google/gemini-cli`.
9. **Brave Browser**: Secure browser installation.
10. **Spotify**: Music player deployed via Flatpak.
11. **Obsidian**: Knowledge base application deployed via Flatpak.
12. **Dank Material Shell**: Automated install script for custom layout and theme engines.
13. **Antigravity CLI**: Installs Google's Antigravity command-line tool.
14. **Niri Configuration Files**: Clones custom desktop configs into `~/.config/niri`.
15. **Zsh Plugins**: `zsh-autosuggestions` and `zsh-syntax-highlighting` installation and integration.
16. **Custom `.zshrc` & Ghostty**: Deploys a fully-configured Zsh profile with custom aliases and tools, plus the Ghostty terminal config into `~/.config/ghostty`. This step runs last because it overwrites `~/.zshrc`; the profile is distro-specific (`config_zsh/Fedora/.zshrc` or `config_zsh/Cachyos/.zshrc`).

---

## Usage

Run the appropriate script for your Linux distribution. `sudo` is optional: the scripts detect when they are not root and re-exec themselves with `sudo` automatically.

### For Fedora Systems
```bash
./Fedora.sh
```

### For CachyOS (Arch) Systems
```bash
./Cachyos.sh
```

On Fedora, the script also installs its basic prerequisites (`git`, `curl`, `util-linux-user`) at startup.

### Execution Modes
When running either script, a status table is shown first, then you can choose from:
1. **Todo automático (All Automatic):** Sequentially executes all 16 configuration steps without pausing.
2. **Interactivo (Interactive Selection):** Prompts for `[s/N]` confirmation (`s` = yes) before executing each step.
3. **Estado (Check Status):** Displays a clean CLI status table identifying which tools are already present on the system.
4. **Salir (Exit):** Clean exit.

After **Todo automático** and **Interactivo**, an operations summary is displayed with one of these states per tool: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido`.

---

## Languages

Read this documentation in:
- [Spanish](README.es.md)
