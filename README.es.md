# Bootstrapper Automatizado de Entorno de Desarrollo para Linux

Este repositorio contiene scripts Bash interactivos guiados por menús y perfiles de configuración para automatizar la preparación completa de un entorno de desarrollo en distribuciones modernas: **Fedora** y **CachyOS** (derivado de Arch Linux).

## Características Clave y Herramientas Instaladas

Los scripts automatizan la configuración de dieciséis (16) herramientas y características del sistema, listadas en el orden exacto en que aparecen en el menú y en la tabla de estado:

1. **Actualización del Sistema**: Refresca repositorios y realiza actualizaciones del sistema (`dnf upgrade --refresh -y` en Fedora, `pacman -Syu` en CachyOS).
2. **Flatpak y Flathub**: Instala Flatpak si falta y registra el repositorio remoto de Flathub para tu usuario (`flatpak remote-add --user --if-not-exists flathub`). Spotify/Obsidian reutilizan este paso automáticamente (`ensure_flatpak`) e instalan `--user` también.
3. **Zsh y Oh My Zsh**: Instala `zsh`, cambia la shell por defecto con `chsh` (avisa si `zsh` no está en `/etc/shells`) e instala `oh-my-zsh` de modo desatendido (`RUNZSH=no CHSH=no KEEP_ZSHRC=yes`). El instalador se descarga primero a una variable para que un `curl` fallido nunca se reporte como éxito, y luego se canaliza a `sh -s`.
4. **Yazi**: Gestor de archivos para terminal ultrarrápido. En Fedora habilita primero el COPR `lihaohong/yazi` (no fatal, sigue con los repos base si falla); el binario se verifica tras instalar.
5. **Neovim y LazyVim**: Editor de texto moderno con plantilla inicial LazyVim. Instala dependencias también — Fedora: `neovim git ripgrep fd-find fzf gcc make unzip` más un enlace `~/.local/bin/fd -> fdfind` para LazyVim/Telescope; CachyOS: `neovim git ripgrep fd`. La plantilla LazyVim se clona de forma atómica con respaldo `.bak-<epoch>` si ya existe `~/.config/nvim`, conservando su `.git` para futuros `git pull`.
6. **Lazygit**: Cliente de terminal para Git. En Fedora habilita el repositorio **Terra** (`terra-release` desde `repos.fyralabs.com`) en vez del antiguo COPR; el binario se verifica tras instalar.
7. **Pokemon Colorscripts**: Despliegue de sprites Pokémon en la terminal (se clona a un dir `mktemp` como tu usuario, se instala con `install.sh` como root).
8. **Gemini Copilot**: Entorno global para Node.js y la herramienta `@google/gemini-cli`. Fija el prefijo de npm en `~/.npm-global` y lo añade al `PATH` tanto en `~/.zshrc` como en `~/.bashrc`.
9. **Brave Browser**: Navegador web seguro vía el instalador oficial (`curl -fsS https://dl.brave.com/install.sh | sh`, con `-o pipefail`); luego se verifica `brave-browser`. En CachyOS esto importa porque Brave no está en los repos oficiales (solo AUR `brave-bin`).
10. **Spotify**: Reproductor de música vía Flatpak `--user` (`com.spotify.Client`).
11. **Obsidian**: Gestor de notas personales vía Flatpak `--user` (`md.obsidian.Obsidian`).
12. **Dank Material Shell**: Script de instalación interactivo (`dankinstall`) que pregunta por el compositor (niri/hyprland) y la terminal (ghostty/kitty/alacritty) antes de configurar los motores de temas y layouts. Corre como tu usuario, nunca como root, con `-o pipefail`. Se omite si `dms` ya está instalado; los logs quedan en `/tmp/dankinstall-*.log`. Debe ejecutarse **antes** de `configs` y `zshrc` (crea el tema `dankcolors` de Ghostty que esos pasos usan).
13. **Antigravity CLI**: Instala la herramienta de línea de comandos Antigravity de Google como tu usuario (`agy` queda en tu `HOME`, verificado en el `PATH` o en `~/.local/bin/agy`).
14. **Configuraciones de Niri**: Clona `https://github.com/fonta81/.BackNiriDank.git` en `~/.config/niri` de forma atómica (si el clon falla no se toca tu config actual) con respaldo `.bak-<epoch>`. Si ya existe una config de Niri (p. ej. creada por DMS), pide confirmación `[s/N]` antes. El clon conserva su `.git` para futuros `git pull`.
15. **Plugins de Zsh**: Instalación e integración automática de `zsh-autosuggestions` y `zsh-syntax-highlighting` desde los paquetes de la distro (`/usr/share/...` en Fedora, `/usr/share/zsh/plugins/...` en Arch) creando un puente `<nombre>.plugin.zsh` en `~/.oh-my-zsh/custom/plugins` que hace `source` al archivo del sistema (un simple symlink al directorio del sistema nunca carga en OMZ). Un bloque `plugins=(` multilínea se deja sin tocar con un aviso; de todos modos el siguiente paso sobrescribe `~/.zshrc`.
16. **`.zshrc` Personalizado y Ghostty**: Aplica un perfil de Zsh optimizado con alias y variables de entorno preconfiguradas, además del config de la terminal Ghostty en `~/.config/ghostty`. Este paso va al final porque sobrescribe `~/.zshrc`; el perfil depende de la distribución (`config_zsh/Fedora/.zshrc` o `config_zsh/Cachyos/.zshrc`), ya incluye ambos plugins y agrega `~/.local/bin` (`fd`, `agy`) al `PATH`. Los archivos existentes se respaldan (`.zshrc.bak.<fecha>` y `.bak-<epoch>` para Ghostty).

---

## Prerrequisitos

- `git` y `curl`. En Fedora, el script además instala sus prerrequisitos básicos (`git`, `curl`, `util-linux-user` para `chsh`) al arrancar (los fallos quedan en `/tmp/linux-setup-prereq.log`); en CachyOS asegura `git` y `curl` vía pacman.
- Cada entrypoint solo corre en su distro (Fedora.sh aborta fuera de Fedora, Cachyos.sh fuera de CachyOS).

## Uso

Ejecuta el script correspondiente a tu distribución de Linux. `sudo` es opcional: los scripts detectan si no son root y se re-ejecutan con `sudo` automáticamente.

Lánzalos desde tu sesión normal de usuario — no desde una shell de root (`sudo -i`) — para que las configs caigan en tu home y no en `/root`. Ejecutado como root puro aborta con error; si de verdad lo necesitas, usa `SUDO_USER=<usuario> sudo -E ./Fedora.sh`.

### Para Sistemas Fedora
```bash
./Fedora.sh
```

### Para Sistemas CachyOS (Arch)
```bash
./Cachyos.sh
```

### Modos de Ejecución
Al iniciar cualquiera de los scripts se muestra primero la tabla de estado y después un menú interactivo con las siguientes opciones:
1. **Todo automático:** Ejecuta secuencialmente los 16 pasos; el paso de Dank Material Shell se pausa (preguntas interactivas de `dankinstall`), y el de Niri pide confirmación `[s/N]` si ya existe una config.
2. **Interactivo:** Solicita confirmación `[s/N]` (`s` = sí) antes de ejecutar cada paso.
3. **Estado:** Muestra una tabla estructurada indicando qué herramientas ya están presentes o configuradas en el sistema.
4. **Salir:** Salida limpia del instalador.

Después de **Todo automático** e **Interactivo** se muestra un resumen de operaciones con uno de estos estados por herramienta: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` (los pasos no tocados muestran `No ejecutado`).

---

## El Orden Importa

- `dank` debe ejecutarse **antes** de `configs` y `zshrc`: `install_configs` sobrescribe `~/.config/niri`, y el config de Ghostty incluido trae `theme = dankcolors`, un tema creado por DMS.
- `zshrc` queda **al final**: sobrescribe `~/.zshrc`, descartando los retoques que el paso `plugins` hizo en `plugins=(` (el `.zshrc` incluido ya trae ambos plugins).

## Respaldos

Las configs sobrescritas nunca se borran en silencio: Niri, Neovim y Ghostty guardan copias `.bak-<epoch>`, y `.zshrc` guarda una copia `.zshrc.bak.<fecha>`. Los clones se despliegan de forma atómica — si el clon falla, la config existente no se toca.

## Estructura del Repositorio

- `Fedora.sh`, `Cachyos.sh` — solo puntos de entrada: cargan `lib/common.sh`, aseguran la detección root/usuario, registran las 16 herramientas y abren el menú.
- `lib/common.sh` — toda la lógica compartida (menús, `install_*`/`check_*`, ayudantes por distro). Se carga con `source`, nunca se ejecuta directo.
- `config_zsh/Fedora/.zshrc`, `config_zsh/Cachyos/.zshrc`, `config_ghostty/config` — payloads que el paso `zshrc` copia al home del usuario destino.
- `Fedora.md` / `Cachyos.md` — notas manuales paso a paso; pueden ir por detrás de los scripts, así que los scripts mandan.

## Verificar Cambios

```bash
bash -n Fedora.sh Cachyos.sh lib/common.sh
```

Esa es la única comprobación segura (no hay tests ni linters instalados). No ejecutes los instaladores para "probar" — actualizan el sistema, ejecutan `chsh` y sobrescriben `~/.zshrc`.

---

## Idiomas

Leer esta documentación en:
- [Inglés](README.md)
