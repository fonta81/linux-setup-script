# Automated Linux Development Environment Bootstrapper

This repository contains personal, interactive, menu-driven Bash automation scripts and configuration profiles designed to bootstrap a complete developer environment on modern Linux distributions: **Fedora** and **CachyOS** (an Arch Linux derivative).

## Key Features & Tools Installed

The scripts automate the setup of sixteen (16) core system features and tools, listed in the exact order they appear in the menu and status table:

1. **System Upgrade**: Refreshes repositories and performs upgrades (`dnf upgrade --refresh -y` on Fedora, `pacman -Syu` on CachyOS).
2. **Flatpak & Flathub**: Installs Flatpak if missing and registers the Flathub remote for your user (`flatpak remote-add --user --if-not-exists flathub`). Spotify/Obsidian reuse this step automatically (`ensure_flatpak`) and install `--user` too.
3. **Zsh & Oh My Zsh**: Installs `zsh`, switches the default shell with `chsh` (warns if `zsh` is missing from `/etc/shells`), and installs `oh-my-zsh` unattended (`RUNZSH=no CHSH=no KEEP_ZSHRC=yes`). The installer is downloaded to a variable first so a failed `curl` is never reported as success, then piped to `sh -s`.
4. **Yazi**: Fast terminal file manager. On Fedora it enables the `lihaohong/yazi` COPR first, skipping that call when the COPR is already enabled (non-fatal either way, it falls back to the base repos). The binary is then verified **as your user** — in your `PATH` or at `~/.local/bin/yazi` — because a `command -v` from root would not see a user-local install and would report a false failure.
5. **Neovim & LazyVim**: Modern extensible text editor and starter template. Installs dependencies too — Fedora: `neovim git ripgrep fd-find fzf gcc make unzip`; CachyOS: `neovim git ripgrep fd`. On Fedora the `fd-find` package already ships the `fd` binary that LazyVim/Telescope look for (`fdfind` is Debian's name for it), so the defensive `~/.local/bin/fd -> fdfind` symlink is only created if an `fdfind` turns up with no `fd` visible to your user — in practice that branch does not run. The LazyVim starter is cloned atomically with a `.bak-<epoch>` backup of any existing `~/.config/nvim`, keeping its `.git` for future `git pull` updates.
6. **Lazygit**: Git terminal client. On Fedora it enables the **Terra** repository (`terra-release` from `repos.fyralabs.com`) instead of the old COPR; the package is only installed when it is missing or the repo is not enabled yet, so re-runs are fast. The binary is verified after install.
7. **Pokemon Colorscripts**: CLI Pokémon sprites viewer (cloned to a `mktemp` dir as your user, installed with `install.sh` as root).
8. **Gemini Copilot**: Local Node.js global environment and `@google/gemini-cli`. Sets the npm prefix to `~/.npm-global` and adds it to `PATH` in both `~/.zshrc` and `~/.bashrc`.
9. **Brave Browser**: Secure browser via the official installer (`curl -fsS https://dl.brave.com/install.sh | sh`, with `-o pipefail`); `brave-browser` is verified afterwards. On CachyOS this matters because Brave is not in the official repos (AUR-only `brave-bin`).
10. **Spotify**: Music player deployed via Flatpak `--user` (`com.spotify.Client`).
11. **Obsidian**: Knowledge base application deployed via Flatpak `--user` (`md.obsidian.Obsidian`).
12. **Dank Material Shell**: Interactive install script (`dankinstall`) that asks for your preferred compositor (niri/hyprland) and terminal (ghostty/kitty/alacritty) before setting up the layout and theme engines. Runs as your user, never as root, with `-o pipefail`. Skipped when `dms` is already installed; installer logs live in `/tmp/dankinstall-*.log`. Must run **before** `configs` and `zshrc` (it creates the `dankcolors` Ghostty theme those steps ship).
13. **Antigravity CLI**: Installs Google's Antigravity command-line tool as your user (`agy` lands in your `HOME`, verified in `PATH` or `~/.local/bin/agy`).
14. **Niri Configuration Files**: Clones `https://github.com/fonta81/.BackNiriDank.git` into `~/.config/niri` atomically (a failed clone never touches your existing config) with a `.bak-<epoch>` backup. If a Niri config already exists (e.g. created by DMS), it asks for `[s/N]` confirmation first. The clone keeps its `.git` so you can `git pull` updates later.
15. **Zsh Plugins**: Installs `zsh-autosuggestions` and `zsh-syntax-highlighting` from distro packages (`/usr/share/...` on Fedora, `/usr/share/zsh/plugins/...` on Arch) and creates a `<name>.plugin.zsh` bridge in `~/.oh-my-zsh/custom/plugins` that sources the system file (a plain symlink to the system directory never loads in OMZ). A bridge or clone this script did **not** generate — e.g. your own git clone of the upstream repo with its own `.plugin.zsh` — is detected and left in place rather than overwritten. A multiline `plugins=(` block is left untouched with a warning; note the next step overwrites `~/.zshrc` anyway.
16. **Custom `.zshrc` & Ghostty**: Deploys a fully-configured Zsh profile with custom aliases and tools, plus the Ghostty terminal config into `~/.config/ghostty`. This step runs last because it overwrites `~/.zshrc`; the profile is distro-specific (`config_zsh/Fedora/.zshrc` or `config_zsh/Cachyos/.zshrc`), already lists both plugins, and adds `~/.local/bin` (`fd`, `agy`) to `PATH`. Existing files are backed up (`.zshrc.bak.<date>` and `.bak-<epoch>` for Ghostty).

---

## Prerequisites

- `git` and `curl`. On Fedora, the script also installs its basic prerequisites (`git`, `curl`, `util-linux-user` for `chsh`) at startup; on CachyOS it ensures `git` and `curl` via pacman. If that step fails the script keeps going and prints the first 20 lines of the failure log at `/tmp/linux-setup-prereq.log`.
- Each entrypoint only runs on its own distro (Fedora.sh aborts outside Fedora, Cachyos.sh outside CachyOS).

## Usage

Run the appropriate script for your Linux distribution. `sudo` is optional: the scripts detect when they are not root and re-exec themselves with `sudo` automatically. The re-exec preserves the interpreter (`sudo bash "$0"`), so `./Fedora.sh` and `bash Fedora.sh` are equivalent — you do not need the executable bit.

Launch them from your normal user session — not from a root shell (`sudo -i`) — so configs land in your home, not `/root`. Running as pure root aborts with an error; if you really need it, use `SUDO_USER=<user> sudo -E ./Fedora.sh`.

### For Fedora Systems
```bash
./Fedora.sh
```

### For CachyOS (Arch) Systems
```bash
./Cachyos.sh
```

### Execution Modes
When running either script, a status table is shown first, then you can choose from:
1. **Todo automático (All Automatic):** Sequentially executes all 16 configuration steps; the Dank Material Shell step pauses (interactive `dankinstall` prompts), and the Niri step asks for `[s/N]` confirmation if a config already exists.
2. **Interactivo (Interactive Selection):** Prompts for `[s/N]` confirmation (`s` = yes) before executing each step.
3. **Estado (Check Status):** Displays a clean CLI status table identifying which tools are already present on the system.
4. **Salir (Exit):** Clean exit.

After **Todo automático** and **Interactivo**, an operations summary is displayed with one of these states per tool: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` (untouched steps show `No ejecutado`).

---

## Order Matters

- `dank` must run **before** `configs` and `zshrc`: `install_configs` overwrites `~/.config/niri`, and the shipped Ghostty config sets `theme = dankcolors`, a theme created by DMS.
- `zshrc` stays **last**: it overwrites `~/.zshrc`, discarding any `plugins=(` edits the `plugins` step made (the shipped `.zshrc` already includes both plugins).

## Backups

Overwritten configs are never deleted silently: Niri, Neovim and Ghostty keep `.bak-<epoch>` copies, and `.zshrc` keeps a `.zshrc.bak.<date>` copy. Clones deploy atomically — if the clone fails, the existing config is left untouched. Missing parent directories (e.g. `~/.config` on a fresh account) are created as your user first, and a `Ctrl-C` in the window between the backup and the final swap puts the backup back in place.

## Repository Layout

- `Fedora.sh`, `Cachyos.sh` — entrypoints only: they source `lib/common.sh`, ensure root/user detection, register the 16 tools, and open the menu.
- `lib/common.sh` — all shared logic (menus, `install_*`/`check_*`, distro helpers). Sourced, never executed directly.
- `config_zsh/Fedora/.zshrc`, `config_zsh/Cachyos/.zshrc`, `config_ghostty/config` — payloads copied into the target user's home by the `zshrc` step.
- `Fedora.md` / `Cachyos.md` — manual step-by-step notes; they can lag the scripts, so the scripts take precedence.

## Verify Changes

```bash
bash -n Fedora.sh Cachyos.sh lib/common.sh config_zsh/Fedora/.zshrc config_zsh/Cachyos/.zshrc
```

That is the only safe check (no tests or linters installed). Do not run the installers to "test" — they upgrade the system, run `chsh`, and overwrite `~/.zshrc`.

---

## Languages

Read this documentation in:
- [Spanish](README.es.md)
