# Linux Development Environment Setup

Interactive Bash setup scripts for **Fedora** and **CachyOS**. Each script registers 23 steps in the order shown below and in the menu.

## Setup steps

1. **System update** — `dnf upgrade --refresh` or `pacman -Syu`.
2. **Homebrew** — installs Linuxbrew as your user. Yazi, Lazygit, LazySSH and Lavat use it; those steps install it automatically if needed. Configure a custom prefix with `BREW_PREFIX=/path`.
3. **Flatpak** — installs Flatpak and adds Flathub for your user. Spotify and Obsidian use it automatically.
4. **Zsh & Oh My Zsh** — installs Zsh, changes the default shell, and installs Oh My Zsh.
5. **Yazi** — terminal file manager, installed with Homebrew.
6. **Neovim & LazyVim** — includes required dependencies (`fd-find` on Fedora, `fd` on CachyOS); preserves existing config in a backup.
7. **Lazygit** — terminal Git client, installed with Homebrew.
8. **Pokemon Colorscripts** — Pokémon sprites in the terminal.
9. **Node.js & npm** — installs both and configures global npm packages under `~/.npm-global`, without `sudo`.
10. **Gemini CLI** — global npm install; installs Node.js/npm as needed if step 9 was skipped.
11. **GitHub Copilot CLI** — official installer; does not require Node.js.
12. **Repomix** — global npm install; installs Node.js/npm as needed if step 9 was skipped.
13. **LazySSH** — terminal SSH manager, installed with Homebrew.
14. **Lavat** — terminal lava-lamp simulation, installed with Homebrew.
15. **Brave Browser** — official installer.
16. **Spotify** — Flatpak installed for your user.
17. **Obsidian** — Flatpak installed for your user.
18. **Dank Material Shell** — interactive setup for compositor and terminal; runs as your user.
19. **Antigravity CLI** — installed as your user.
20. **OpenCode** — installed as your user.
21. **Niri configuration** — deploys the Niri config; asks before replacing an existing one.
22. **Zsh plugins** — installs autosuggestions and syntax highlighting.
23. **Zsh & Ghostty configuration** — deploys distro-specific profiles and PATH settings.

## Requirements and usage

- Requires Fedora or CachyOS, `git` and `curl`. The scripts install their startup prerequisites and reject other distributions.
- Run the matching script from your **normal user session**, not a root shell. `sudo` is optional; the script re-executes itself as root while preserving your user. Pure root execution is rejected to avoid installing configs into `/root`.

```bash
./Fedora.sh    # Fedora
./Cachyos.sh   # CachyOS
```

The menu offers:
- **Todo automático** — runs all steps. Dank Material Shell remains interactive; Niri asks before replacing an existing config.
- **Interactivo** — asks before each step; `a` accepts the remaining steps. Internal prompts still apply.
- **Estado** — shows which tools are installed.
- **Salir** — exits.

The summary reports `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` or `No ejecutado`.

## Important order and backups

- Homebrew runs early because four tools depend on it.
- Run Dank Material Shell before Niri and Ghostty configuration; it provides the `dankcolors` theme.
- Zsh configuration runs last because it overwrites `~/.zshrc`; the shipped profiles already include both plugins and required PATH entries.
- Existing Niri, Neovim, Ghostty and Zsh configs are backed up. Config clones deploy atomically, so a failed clone leaves the current config in place.

## Repository and safe verification

- `Fedora.sh` and `Cachyos.sh` are entrypoints; shared logic is in `lib/common.sh`.
- `config_zsh/` and `config_ghostty/` contain deployed profiles. `Doc/` contains legacy runbooks; the scripts take precedence.
- Syntax check: `bash -n Fedora.sh Cachyos.sh lib/common.sh config_zsh/Fedora/.zshrc config_zsh/Cachyos/.zshrc`
- **Do not run the installers to test changes:** they modify the system, run `chsh` and overwrite configuration files. No automated tests or linters are provided.

---

## Languages

- [Spanish](README.es.md)

## License

- [License MIT](LICENSE) 