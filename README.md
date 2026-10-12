# Automated Linux Development Environment Bootstrapper

This repository contains personal, interactive, menu-driven Bash automation scripts and configuration profiles designed to bootstrap a complete developer environment on modern Linux distributions: **Fedora** and **CachyOS** (an Arch Linux derivative).

## Key Features & Tools Installed

The scripts automate the setup of twenty-three (23) core system features and tools, listed in the exact order they appear in the menu and status table:

1. **System Upgrade**: Refreshes repositories and performs upgrades (`dnf upgrade --refresh -y` on Fedora, `pacman -Syu` on CachyOS).
2. **Homebrew**: Installs Linuxbrew from the official `install.sh`, as your user and never as root, with `NONINTERACTIVE=1` and `-o pipefail`. It first installs the build tools Homebrew requires on Linux (`development-tools` + `procps-ng curl file` on Fedora, `base-devel procps-ng curl file git` on Arch; non-fatal) and pre-creates `/home/linuxbrew` owned by you — without that directory the installer calls `sudo -n`, cannot prompt for a password, and aborts with *"Insufficient permissions to install Homebrew"*. The step is idempotent (a second run reports `Éxito (Ya existía)`) and writes the **guarded** three-line `brew shellenv` block — the same one the shipped `.zshrc` carries — to both `~/.zshrc` and `~/.bashrc`, idempotently and without duplicating anything. That block is written by the script itself because upstream never edits an rc file: it only *prints* the command and picks the file from `$SHELL`, which is unreliable under `sudo`. Only the Linuxbrew prefix is supported (`/home/linuxbrew/.linuxbrew`); override it with `BREW_PREFIX=/ruta ./Fedora.sh`. Yazi, Lazygit, LazySSH and Lavat reuse this step automatically (`ensure_brew`), and that side-effect install deliberately does **not** change the `brew` row of the summary.
3. **Flatpak & Flathub**: Installs Flatpak if missing and registers the Flathub remote for your user (`flatpak remote-add --user --if-not-exists flathub`). Spotify/Obsidian reuse this step automatically (`ensure_flatpak`) and install `--user` too.
4. **Zsh & Oh My Zsh**: Installs `zsh`, switches the default shell with `chsh` (warns if `zsh` is missing from `/etc/shells`), and installs `oh-my-zsh` unattended (`RUNZSH=no CHSH=no KEEP_ZSHRC=yes`). The installer is downloaded to a variable first so a failed `curl` is never reported as success, then piped to `sh -s`.
5. **Yazi**: Fast terminal file manager, installed with `brew install --formula yazi` (the old `lihaohong/yazi` COPR dance on Fedora is gone). The binary is then verified with `brew_has_binary`, i.e. inside the Homebrew prefix: that directory is **not** in root's `PATH`, so a plain `command -v` would report a false failure — and a leftover `yazi` from pacman would report a false success.
6. **Neovim & LazyVim**: Modern extensible text editor and starter template. Installs dependencies too — Fedora: `neovim git ripgrep fd-find fzf gcc make unzip`; CachyOS: `neovim git ripgrep fd`. On Fedora the `fd-find` package already ships the `fd` binary that LazyVim/Telescope look for (`fdfind` is Debian's name for it), so the defensive `~/.local/bin/fd -> fdfind` symlink is only created if an `fdfind` turns up with no `fd` visible to your user — in practice that branch does not run. The LazyVim starter is cloned atomically with a `.bak-<epoch>` backup of any existing `~/.config/nvim`, keeping its `.git` for future `git pull` updates.
7. **Lazygit**: Git terminal client, installed with `brew install --formula lazygit`. This replaces the entire Fedora **Terra** repository setup (`terra-release`/`terra-gpg-keys`, the `repo_gpgcheck` workaround for unsynced clocks and the `NTPSynchronized` warning) plus the sha256-verified GitHub tarball fallback; upstream ships an official formula with Linux bottles. The binary is verified in the Homebrew prefix with `brew_has_binary`, so a `lazygit` left over from a distro repo doesn't count as this step's install.
8. **Pokemon Colorscripts**: CLI Pokémon sprites viewer (cloned to a `mktemp` dir as your user, installed with `install.sh` as root).
9. **Node.js & npm**: Installs the `nodejs` and `npm` packages from your distro and verifies both binaries afterwards. It then configures the global npm prefix — `~/.npm-global` — so global installs never need `sudo`, and adds it to `PATH` in both `~/.zshrc` and `~/.bashrc` (idempotently: nothing is appended twice).
10. **Gemini Copilot**: Installs `@google/gemini-cli` globally with `npm install -g`. If Node.js/npm are missing — e.g. you skipped the previous step in interactive mode — they are installed here as a side effect (with a warning); that install does not change the result of the Node.js step itself, which stays `No ejecutado`. The binary is verified in `PATH` or `~/.npm-global/bin/gemini`. Note the next step overwrites `~/.zshrc`, so the npm `PATH` line added earlier is re-added by the shipped profile.
11. **Copilot CLI**: GitHub's terminal-native AI assistant via the official installer (`curl -fsSL https://gh.io/copilot-install | bash`, with `-o pipefail`), installed as root into `/usr/local/bin/copilot` so it is visible to every user. No Node.js dependency. The binary is verified afterwards.
12. **Repomix**: Packs a repository into a single AI-friendly file. Installs `repomix` globally with `npm install -g` (same Node.js side-effect pattern as Gemini: missing Node.js/npm are installed without touching the Node.js step result). The binary is verified in `PATH` or `~/.npm-global/bin/repomix`.
13. **LazySSH**: Terminal SSH manager (`Adembc/lazyssh`), installed with `brew install --formula lazyssh`. It has no distro package, but its formula is in homebrew-core with Linux bottles, so the GitHub tarball download and sha256 verification are no longer needed. The binary is verified in the Homebrew prefix with `brew_has_binary`.
14. **Lavat**: Lava-lamp simulation for the terminal (`AngelJumbo/lavat`), installed with `brew install --formula lavat`. It used to build from source on both distros (`gcc`/`make` + `git clone` + `make && make install` into `/usr/local/bin`); the homebrew-core formula ships Linux bottles and removes that whole path. The binary is verified in the Homebrew prefix with `brew_has_binary` — precisely so an old `/usr/local/bin/lavat` from that build-from-source path can't pass as a successful brew install.
15. **Brave Browser**: Secure browser via the official installer (`curl -fsS https://dl.brave.com/install.sh | sh`, with `-o pipefail`); `brave-browser` is verified afterwards. On CachyOS this matters because Brave is not in the official repos (AUR-only `brave-bin`).
16. **Spotify**: Music player deployed via Flatpak `--user` (`com.spotify.Client`).
17. **Obsidian**: Knowledge base application deployed via Flatpak `--user` (`md.obsidian.Obsidian`).
18. **Dank Material Shell**: Interactive install script (`dankinstall`) that asks for your preferred compositor (niri/hyprland) and terminal (ghostty/kitty/alacritty) before setting up the layout and theme engines. Runs as your user, never as root, with `-o pipefail`. Skipped when `dms` is already installed; installer logs live in `/tmp/dankinstall-*.log`. Must run **before** `configs` and `zshrc` (it creates the `dankcolors` Ghostty theme those steps ship).
19. **Antigravity CLI**: Installs Google's Antigravity command-line tool as your user (`agy` lands in your `HOME`, verified in `PATH` or `~/.local/bin/agy`).
20. **OpenCode**: Terminal-native AI coding agent via the official installer (`curl -fsSL https://opencode.ai/install | bash`, with `-o pipefail`), installed as your user into `~/.opencode/bin` so it is identical on both distros. The binary is verified in your `PATH` or `~/.opencode/bin/opencode`.
21. **Niri Configuration Files**: Clones `https://github.com/fonta81/.BackNiriDank.git` into `~/.config/niri` atomically (a failed clone never touches your existing config) with a `.bak-<epoch>` backup. If a Niri config already exists (e.g. created by DMS), it asks for `[s/N]` confirmation first. The clone keeps its `.git` so you can `git pull` updates later.
22. **Zsh Plugins**: Installs `zsh-autosuggestions` and `zsh-syntax-highlighting` from distro packages (`/usr/share/...` on Fedora, `/usr/share/zsh/plugins/...` on Arch) and creates a `<name>.plugin.zsh` bridge in `~/.oh-my-zsh/custom/plugins` that sources the system file (a plain symlink to the system directory never loads in OMZ). A bridge or clone this script did **not** generate — e.g. your own git clone of the upstream repo with its own `.plugin.zsh` — is detected and left in place rather than overwritten. A multiline `plugins=(` block is left untouched with a warning; note the next step overwrites `~/.zshrc` anyway.
23. **Custom `.zshrc` & Ghostty**: Deploys a fully-configured Zsh profile with custom aliases and tools, plus the Ghostty terminal config into `~/.config/ghostty`. This step runs last because it overwrites `~/.zshrc`; the profile is distro-specific (`config_zsh/Fedora/.zshrc` or `config_zsh/Cachyos/.zshrc`), already lists both plugins, and adds `~/.local/bin` (`fd`, `agy`), `~/.npm-global/bin` and `~/.opencode/bin` to `PATH`. Existing files are backed up (`.zshrc.bak.<date>` and `.bak-<epoch>` for Ghostty).

---

## Prerequisites

- `git` and `curl`. On Fedora, the script also installs its basic prerequisites (`git`, `curl`, `util-linux-user` for `chsh`) at startup; on CachyOS it ensures `git` and `curl` via pacman. If that step fails the script keeps going and prints the first 20 lines of the failure log at `/tmp/linux-setup-prereq.log`.
- Each entrypoint only runs on its own distro (Fedora.sh aborts outside Fedora, Cachyos.sh outside CachyOS).
- Nothing else is needed for the Homebrew step: it installs its own build tools (`development-tools`/`base-devel` + `procps-ng curl file`) and then the official `install.sh`.

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
1. **Todo automático (All Automatic):** Sequentially executes all 23 configuration steps (the first run of the Homebrew step can take a few minutes while it clones the Homebrew repository); the Dank Material Shell step pauses (interactive `dankinstall` prompts), and the Niri step asks for `[s/N]` confirmation if a config already exists.
2. **Interactivo (Interactive Selection):** Prompts for `[s/N/a]` confirmation (`s` = yes, `a` = yes and install everything that remains without asking again) before executing each step. "Yes to all" does not affect the internal prompts: Niri still asks for `[s/N]` confirmation if a config already exists, and `dankinstall` is still interactive.
3. **Estado (Check Status):** Displays a clean CLI status table identifying which tools are already present on the system.
4. **Salir (Exit):** Clean exit.

After **Todo automático** and **Interactivo**, an operations summary is displayed with one of these states per tool: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` (untouched steps show `No ejecutado`).

---

## Order Matters

- `brew` comes **first** (right after `update`): Yazi, Lazygit, LazySSH and Lavat install through it. Skipping it in interactive mode is safe — those steps call `ensure_brew` and install Homebrew as a side effect — and that side effect never touches the `brew` row, so it keeps the state you gave it (`Omitido` if you declined it, `No ejecutado` in automatic mode).
- `dank` must run **before** `configs` and `zshrc`: `install_configs` overwrites `~/.config/niri`, and the shipped Ghostty config sets `theme = dankcolors`, a theme created by DMS.
- `zshrc` stays **last**: it overwrites `~/.zshrc`, discarding any `plugins=(` edits the `plugins` step made (the shipped `.zshrc` already includes both plugins).

## Backups

Overwritten configs are never deleted silently: Niri, Neovim and Ghostty keep `.bak-<epoch>` copies, and `.zshrc` keeps a `.zshrc.bak.<date>` copy. Clones deploy atomically — if the clone fails, the existing config is left untouched. Missing parent directories (e.g. `~/.config` on a fresh account) are created as your user first, and a `Ctrl-C` in the window between the backup and the final swap puts the backup back in place.

## Repository Layout

- `Fedora.sh`, `Cachyos.sh` — entrypoints only: they source `lib/common.sh`, ensure root/user detection, register the 23 tools, and open the menu.
- `lib/common.sh` — all shared logic (menus, `install_*`/`check_*`, distro helpers, plus the shared `brew_install`/`ensure_brew`/`brew_has_binary`/`cmd_available`, `ensure_node_for`/`npm_install_global` and `install_flatpak_app` helpers). Sourced, never executed directly.
- `config_zsh/Fedora/.zshrc`, `config_zsh/Cachyos/.zshrc`, `config_ghostty/config` — payloads copied into the target user's home by the `zshrc` step.
- `Doc/Fedora.md` / `Doc/Cachyos.md` — manual step-by-step notes; they can lag the scripts, so the scripts take precedence.

## Verify Changes

```bash
bash -n Fedora.sh Cachyos.sh lib/common.sh config_zsh/Fedora/.zshrc config_zsh/Cachyos/.zshrc
```

That is the only safe check (no tests or linters installed). Do not run the installers to "test" — they upgrade the system, run `chsh`, and overwrite `~/.zshrc`.

---

## Languages

Read this documentation in:
- [Spanish](README.es.md)
