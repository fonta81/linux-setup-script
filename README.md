# Automated Linux Development Environment Bootstrapper

This repository contains personal, interactive, menu-driven Bash automation scripts and configuration profiles designed to bootstrap a complete developer environment on modern Linux distributions: **Fedora** and **CachyOS** (an Arch Linux derivative).

## Key Features & Tools Installed

The scripts automate the setup of twenty-one (21) core system features and tools, listed in the exact order they appear in the menu and status table:

1. **System Upgrade**: Refreshes repositories and performs upgrades (`dnf upgrade --refresh -y` on Fedora, `pacman -Syu` on CachyOS).
2. **Flatpak & Flathub**: Installs Flatpak if missing and registers the Flathub remote for your user (`flatpak remote-add --user --if-not-exists flathub`). Spotify/Obsidian reuse this step automatically (`ensure_flatpak`) and install `--user` too.
3. **Zsh & Oh My Zsh**: Installs `zsh`, switches the default shell with `chsh` (warns if `zsh` is missing from `/etc/shells`), and installs `oh-my-zsh` unattended (`RUNZSH=no CHSH=no KEEP_ZSHRC=yes`). The installer is downloaded to a variable first so a failed `curl` is never reported as success, then piped to `sh -s`.
4. **Yazi**: Fast terminal file manager. On Fedora it enables the `lihaohong/yazi` COPR first, skipping that call when the COPR is already enabled (non-fatal either way, it falls back to the base repos). The binary is then verified **as your user** — in your `PATH` or at `~/.local/bin/yazi` — because a `command -v` from root would not see a user-local install and would report a false failure.
5. **Neovim & LazyVim**: Modern extensible text editor and starter template. Installs dependencies too — Fedora: `neovim git ripgrep fd-find fzf gcc make unzip`; CachyOS: `neovim git ripgrep fd`. On Fedora the `fd-find` package already ships the `fd` binary that LazyVim/Telescope look for (`fdfind` is Debian's name for it), so the defensive `~/.local/bin/fd -> fdfind` symlink is only created if an `fdfind` turns up with no `fd` visible to your user — in practice that branch does not run. The LazyVim starter is cloned atomically with a `.bak-<epoch>` backup of any existing `~/.config/nvim`, keeping its `.git` for future `git pull` updates.
6. **Lazygit**: Git terminal client. On Fedora it enables the **Terra** repository (`terra-release` + `terra-gpg-keys` from `repos.fyralabs.com`) instead of the old COPR; the setup is only re-run when the release, the keys, the repo or the key file is missing, so re-runs are fast. `repo_gpgcheck` is disabled for Terra only (the RPM's own signature is still verified) because rpm-sequoia can reject Terra's otherwise-valid metadata signature on an unsynced clock; the script warns if `NTPSynchronized` is not `yes`. If the package still can't be installed, it retries with clean metadata and finally falls back to the official GitHub release tarball, verified against its `checksums.txt`. The binary is verified after install.
7. **Pokemon Colorscripts**: CLI Pokémon sprites viewer (cloned to a `mktemp` dir as your user, installed with `install.sh` as root).
8. **Node.js & npm**: Installs the `nodejs` and `npm` packages from your distro and verifies both binaries afterwards. It then configures the global npm prefix — `~/.npm-global` — so global installs never need `sudo`, and adds it to `PATH` in both `~/.zshrc` and `~/.bashrc` (idempotently: nothing is appended twice).
9. **Gemini Copilot**: Installs `@google/gemini-cli` globally with `npm install -g`. If Node.js/npm are missing — e.g. you skipped the previous step in interactive mode — they are installed here as a side effect (with a warning); that install does not change the result of the Node.js step itself, which stays `No ejecutado`. Note the next step overwrites `~/.zshrc`, so the npm `PATH` line added earlier is re-added by the shipped profile.
10. **Copilot CLI**: GitHub's terminal-native AI assistant via the official installer (`curl -fsSL https://gh.io/copilot-install | bash`, with `-o pipefail`), installed as root into `/usr/local/bin/copilot` so it is visible to every user. No Node.js dependency. The binary is verified afterwards.
11. **Repomix**: Packs a repository into a single AI-friendly file. Installs `repomix` globally with `npm install -g` (same Node.js side-effect pattern as Gemini: missing Node.js/npm are installed without touching the Node.js step result). The binary is verified in `PATH` or `~/.npm-global/bin/repomix`.
12. **LazySSH**: Terminal SSH manager (`Adembc/lazyssh`). No distro package, so it downloads the official `lazyssh_Linux_<arch>` tarball from GitHub releases into a `mktemp` dir, verifies its sha256 against the release `checksums.txt` (aborts on mismatch, same strictness as Lazygit), extracts and installs to `/usr/local/bin`. The binary is verified afterwards.
13. **Lavat**: Lava-lamp simulation for the terminal (`AngelJumbo/lavat`, from `main`). No Fedora package and no AUR helper in this project, so it builds from source identically on both distros: installs `gcc`/`make`, clones as your user into a `mktemp` dir, runs `make && make install` as root (`/usr/local/bin`), and cleans the temp dir on both paths. The binary is verified afterwards.
14. **Brave Browser**: Secure browser via the official installer (`curl -fsS https://dl.brave.com/install.sh | sh`, with `-o pipefail`); `brave-browser` is verified afterwards. On CachyOS this matters because Brave is not in the official repos (AUR-only `brave-bin`).
15. **Spotify**: Music player deployed via Flatpak `--user` (`com.spotify.Client`).
16. **Obsidian**: Knowledge base application deployed via Flatpak `--user` (`md.obsidian.Obsidian`).
17. **Dank Material Shell**: Interactive install script (`dankinstall`) that asks for your preferred compositor (niri/hyprland) and terminal (ghostty/kitty/alacritty) before setting up the layout and theme engines. Runs as your user, never as root, with `-o pipefail`. Skipped when `dms` is already installed; installer logs live in `/tmp/dankinstall-*.log`. Must run **before** `configs` and `zshrc` (it creates the `dankcolors` Ghostty theme those steps ship).
18. **Antigravity CLI**: Installs Google's Antigravity command-line tool as your user (`agy` lands in your `HOME`, verified in `PATH` or `~/.local/bin/agy`).
19. **Niri Configuration Files**: Clones `https://github.com/fonta81/.BackNiriDank.git` into `~/.config/niri` atomically (a failed clone never touches your existing config) with a `.bak-<epoch>` backup. If a Niri config already exists (e.g. created by DMS), it asks for `[s/N]` confirmation first. The clone keeps its `.git` so you can `git pull` updates later.
20. **Zsh Plugins**: Installs `zsh-autosuggestions` and `zsh-syntax-highlighting` from distro packages (`/usr/share/...` on Fedora, `/usr/share/zsh/plugins/...` on Arch) and creates a `<name>.plugin.zsh` bridge in `~/.oh-my-zsh/custom/plugins` that sources the system file (a plain symlink to the system directory never loads in OMZ). A bridge or clone this script did **not** generate — e.g. your own git clone of the upstream repo with its own `.plugin.zsh` — is detected and left in place rather than overwritten. A multiline `plugins=(` block is left untouched with a warning; note the next step overwrites `~/.zshrc` anyway.
21. **Custom `.zshrc` & Ghostty**: Deploys a fully-configured Zsh profile with custom aliases and tools, plus the Ghostty terminal config into `~/.config/ghostty`. This step runs last because it overwrites `~/.zshrc`; the profile is distro-specific (`config_zsh/Fedora/.zshrc` or `config_zsh/Cachyos/.zshrc`), already lists both plugins, and adds `~/.local/bin` (`fd`, `agy`) and `~/.npm-global/bin` to `PATH`. Existing files are backed up (`.zshrc.bak.<date>` and `.bak-<epoch>` for Ghostty).

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
1. **Todo automático (All Automatic):** Sequentially executes all 21 configuration steps; the Dank Material Shell step pauses (interactive `dankinstall` prompts), and the Niri step asks for `[s/N]` confirmation if a config already exists.
2. **Interactivo (Interactive Selection):** Prompts for `[s/N/a]` confirmation (`s` = yes, `a` = yes and install everything that remains without asking again) before executing each step. "Yes to all" does not affect the internal prompts: Niri still asks for `[s/N]` confirmation if a config already exists, and `dankinstall` is still interactive.
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

- `Fedora.sh`, `Cachyos.sh` — entrypoints only: they source `lib/common.sh`, ensure root/user detection, register the 21 tools, and open the menu.
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
