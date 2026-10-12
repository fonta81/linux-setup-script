# Bootstrapper Automatizado de Entorno de Desarrollo para Linux

Este repositorio contiene scripts Bash interactivos guiados por menús y perfiles de configuración para automatizar la preparación completa de un entorno de desarrollo en distribuciones modernas: **Fedora** y **CachyOS** (derivado de Arch Linux).

## Características Clave y Herramientas Instaladas

Los scripts automatizan la configuración de veintitrés (23) herramientas y características del sistema, listadas en el orden exacto en que aparecen en el menú y en la tabla de estado:

1. **Actualización del Sistema**: Refresca repositorios y realiza actualizaciones del sistema (`dnf upgrade --refresh -y` en Fedora, `pacman -Syu` en CachyOS).
2. **Homebrew**: Instala Linuxbrew con el `install.sh` oficial, como tu usuario y nunca como root, con `NONINTERACTIVE=1` y `-o pipefail`. Primero instala las herramientas de compilación que Homebrew exige en Linux (`development-tools` + `procps-ng curl file` en Fedora, `base-devel procps-ng curl file git` en Arch; no es fatal) y precrea `/home/linuxbrew` a tu nombre — sin ese directorio el instalador usa `sudo -n`, no puede pedir contraseña y aborta con *"Insufficient permissions to install Homebrew"*. El paso es idempotente (una segunda corrida reporta `Éxito (Ya existía)`) y escribe el bloque **guardado** de tres líneas de `brew shellenv` — el mismo que trae el `.zshrc` incluido — en `~/.zshrc` y `~/.bashrc`, de forma idempotente y sin duplicar nada. Ese bloque lo escribe el propio script porque upstream nunca edita un rc file: solo *imprime* el comando y elige el archivo según `$SHELL`, lo cual no es fiable bajo `sudo`. Solo se soporta el prefijo de Linuxbrew (`/home/linuxbrew/.linuxbrew`); se puede cambiar con `BREW_PREFIX=/ruta ./Fedora.sh`. Yazi, Lazygit, LazySSH y Lavat reutilizan este paso automáticamente (`ensure_brew`), y esa instalación como efecto secundario **no** modifica la fila `brew` del resumen.
3. **Flatpak y Flathub**: Instala Flatpak si falta y registra el repositorio remoto de Flathub para tu usuario (`flatpak remote-add --user --if-not-exists flathub`). Spotify/Obsidian reutilizan este paso automáticamente (`ensure_flatpak`) e instalan `--user` también.
4. **Zsh y Oh My Zsh**: Instala `zsh`, cambia la shell por defecto con `chsh` (avisa si `zsh` no está en `/etc/shells`) e instala `oh-my-zsh` de modo desatendido (`RUNZSH=no CHSH=no KEEP_ZSHRC=yes`). El instalador se descarga primero a una variable para que un `curl` fallido nunca se reporte como éxito, y luego se canaliza a `sh -s`.
5. **Yazi**: Gestor de archivos para terminal ultrarrápido, instalado con `brew install --formula yazi` (desaparece el dance del COPR `lihaohong/yazi` en Fedora). El binario se verifica con `brew_has_binary`, o sea dentro del prefijo de Homebrew: ese directorio **no** está en el `PATH` de root, así que un `command -v` a secas reportaría un fallo falso — y un `yazi` que haya quedado de pacman reportaría un éxito falso.
6. **Neovim y LazyVim**: Editor de texto moderno con plantilla inicial LazyVim. Instala dependencias también — Fedora: `neovim git ripgrep fd-find fzf gcc make unzip`; CachyOS: `neovim git ripgrep fd`. En Fedora el paquete `fd-find` ya trae el binario `fd` que buscan LazyVim/Telescope (`fdfind` es el nombre que le da Debian), así que el enlace defensivo `~/.local/bin/fd -> fdfind` solo se crea si apareciera un `fdfind` sin ningún `fd` visible para tu usuario — en la práctica esa rama no se ejecuta. La plantilla LazyVim se clona de forma atómica con respaldo `.bak-<epoch>` si ya existe `~/.config/nvim`, conservando su `.git` para futuros `git pull`.
7. **Lazygit**: Cliente de terminal para Git, instalado con `brew install --formula lazygit`. Esto reemplaza toda la configuración del repositorio **Terra** en Fedora (`terra-release`/`terra-gpg-keys`, el rodeo de `repo_gpgcheck` para relojes sin sincronizar y el aviso de `NTPSynchronized`) más el fallback al tarball de GitHub verificado por sha256: upstream publica una fórmula oficial con bottles para Linux. El binario se verifica en el prefijo de Homebrew con `brew_has_binary`, así que un `lazygit` heredado de un repo de distro no cuenta como la instalación de este paso.
8. **Pokemon Colorscripts**: Despliegue de sprites Pokémon en la terminal (se clona a un dir `mktemp` como tu usuario, se instala con `install.sh` como root).
9. **Node.js y npm**: Instala los paquetes `nodejs` y `npm` de tu distro y verifica después que ambos binarios existen. Luego configura el prefijo global de npm — `~/.npm-global` — para que las instalaciones globales nunca necesiten `sudo`, y lo añade al `PATH` tanto en `~/.zshrc` como en `~/.bashrc` (de forma idempotente: no se añade dos veces).
10. **Gemini Copilot**: Instala `@google/gemini-cli` globalmente con `npm install -g`. Si Node.js/npm no están — p. ej. porque omitiste el paso anterior en modo interactivo — se instalan aquí como efecto secundario (con un aviso); esa instalación no cambia el resultado del paso de Node.js, que sigue en `No ejecutado`. El binario se verifica en el `PATH` o en `~/.npm-global/bin/gemini`. Ten en cuenta que el último paso sobrescribe `~/.zshrc`, así que la línea de `PATH` de npm añadida antes la vuelve a poner el perfil que se despliega.
11. **Copilot CLI**: Asistente IA de GitHub para la terminal vía el instalador oficial (`curl -fsSL https://gh.io/copilot-install | bash`, con `-o pipefail`), instalado como root en `/usr/local/bin/copilot` para que quede visible a todos. Sin dependencia de Node.js. El binario se verifica después.
12. **Repomix**: Empaqueta un repositorio en un solo archivo apto para IA. Instala `repomix` globalmente con `npm install -g` (mismo patrón de dependencia de Node.js que Gemini: si faltan Node.js/npm se instalan sin tocar el resultado del paso de Node.js). El binario se verifica en el `PATH` o en `~/.npm-global/bin/repomix`.
13. **LazySSH**: Gestor SSH en terminal (`Adembc/lazyssh`), instalado con `brew install --formula lazyssh`. No tiene paquete de distro, pero su fórmula está en homebrew-core con bottles para Linux, así que ya no hacen falta la descarga del tarball de GitHub ni la verificación sha256. El binario se verifica en el prefijo de Homebrew con `brew_has_binary`.
14. **Lavat**: Simulación de lámpara de lava para la terminal (`AngelJumbo/lavat`), instalado con `brew install --formula lavat`. Antes se compilaba desde el código fuente en ambas distros (`gcc`/`make` + `git clone` + `make && make install` en `/usr/local/bin`); la fórmula de homebrew-core trae bottles para Linux y elimina todo ese camino. El binario se verifica en el prefijo de Homebrew con `brew_has_binary`, precisamente para que un `/usr/local/bin/lavat` viejo de aquella compilación no pase por una instalación de brew exitosa.
15. **Brave Browser**: Navegador web seguro vía el instalador oficial (`curl -fsS https://dl.brave.com/install.sh | sh`, con `-o pipefail`); luego se verifica `brave-browser`. En CachyOS esto importa porque Brave no está en los repos oficiales (solo AUR `brave-bin`).
16. **Spotify**: Reproductor de música vía Flatpak `--user` (`com.spotify.Client`).
17. **Obsidian**: Gestor de notas personales vía Flatpak `--user` (`md.obsidian.Obsidian`).
18. **Dank Material Shell**: Script de instalación interactivo (`dankinstall`) que pregunta por el compositor (niri/hyprland) y la terminal (ghostty/kitty/alacritty) antes de configurar los motores de temas y layouts. Corre como tu usuario, nunca como root, con `-o pipefail`. Se omite si `dms` ya está instalado; los logs quedan en `/tmp/dankinstall-*.log`. Debe ejecutarse **antes** de `configs` y `zshrc` (crea el tema `dankcolors` de Ghostty que esos pasos usan).
19. **Antigravity CLI**: Instala la herramienta de línea de comandos Antigravity de Google como tu usuario (`agy` queda en tu `HOME`, verificado en el `PATH` o en `~/.local/bin/agy`).
20. **OpenCode**: Agente de codificación IA para la terminal vía el instalador oficial (`curl -fsSL https://opencode.ai/install | bash`, con `-o pipefail`), instalado como tu usuario en `~/.opencode/bin` para que sea idéntico en ambas distros. El binario se verifica en tu `PATH` o en `~/.opencode/bin/opencode`.
21. **Configuraciones de Niri**: Clona `https://github.com/fonta81/.BackNiriDank.git` en `~/.config/niri` de forma atómica (si el clon falla no se toca tu config actual) con respaldo `.bak-<epoch>`. Si ya existe una config de Niri (p. ej. creada por DMS), pide confirmación `[s/N]` antes. El clon conserva su `.git` para futuros `git pull`.
22. **Plugins de Zsh**: Instalación e integración automática de `zsh-autosuggestions` y `zsh-syntax-highlighting` desde los paquetes de la distro (`/usr/share/...` en Fedora, `/usr/share/zsh/plugins/...` en Arch) creando un puente `<nombre>.plugin.zsh` en `~/.oh-my-zsh/custom/plugins` que hace `source` al archivo del sistema (un simple symlink al directorio del sistema nunca carga en OMZ). Un puente o clon que este script **no** generó — p. ej. tu propio clon git del upstream con su propio `.plugin.zsh` — se detecta y se deja en su sitio en lugar de sobrescribirse. Un bloque `plugins=(` multilínea se deja sin tocar con un aviso; de todos modos el siguiente paso sobrescribe `~/.zshrc`.
23. **`.zshrc` Personalizado y Ghostty**: Aplica un perfil de Zsh optimizado con alias y variables de entorno preconfiguradas, además del config de la terminal Ghostty en `~/.config/ghostty`. Este paso va al final porque sobrescribe `~/.zshrc`; el perfil depende de la distribución (`config_zsh/Fedora/.zshrc` o `config_zsh/Cachyos/.zshrc`), ya incluye ambos plugins y agrega `~/.local/bin` (`fd`, `agy`), `~/.npm-global/bin` y `~/.opencode/bin` al `PATH`, más un bloque guardado (`if [ -x … ]`) que evalúa `brew shellenv` solo si Homebrew está instalado. Los archivos existentes se respaldan (`.zshrc.bak.<fecha>` y `.bak-<epoch>` para Ghostty).

---

## Prerrequisitos

- `git` y `curl`. En Fedora, el script además instala sus prerrequisitos básicos (`git`, `curl`, `util-linux-user` para `chsh`) al arrancar; en CachyOS asegura `git` y `curl` vía pacman. Si ese paso falla, el script continúa e imprime las primeras 20 líneas del log de fallo en `/tmp/linux-setup-prereq.log`.
- Cada entrypoint solo corre en su distro (Fedora.sh aborta fuera de Fedora, Cachyos.sh fuera de CachyOS).
- No hace falta nada más para el paso de Homebrew: él instala sus propias herramientas de compilación (`development-tools`/`base-devel` + `procps-ng curl file`) y después el `install.sh` oficial.

## Uso

Ejecuta el script correspondiente a tu distribución de Linux. `sudo` es opcional: los scripts detectan si no son root y se re-ejecutan con `sudo` automáticamente. La re-ejecución preserva el intérprete (`sudo bash "$0"`), así que `./Fedora.sh` y `bash Fedora.sh` son equivalentes — no hace falta el bit de ejecución.

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
1. **Todo automático:** Ejecuta secuencialmente los 23 pasos (la primera corrida del paso de Homebrew puede tardar varios minutos mientras clona el repositorio de Homebrew); el paso de Dank Material Shell se pausa (preguntas interactivas de `dankinstall`), y el de Niri pide confirmación `[s/N]` si ya existe una config.
2. **Interactivo:** Solicita confirmación `[s/N/a]` (`s` = sí, `a` = sí e instala todo lo que resta sin volver a preguntar) antes de ejecutar cada paso. El sí a todo no afecta a las preguntas internas: Niri sigue pidiendo confirmación `[s/N]` si ya existe una config, y `dankinstall` sigue siendo interactivo.
3. **Estado:** Muestra una tabla estructurada indicando qué herramientas ya están presentes o configuradas en el sistema.
4. **Salir:** Salida limpia del instalador.

Después de **Todo automático** e **Interactivo** se muestra un resumen de operaciones con uno de estos estados por herramienta: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` (los pasos no tocados muestran `No ejecutado`).

---

## El Orden Importa

- `brew` va **primero** (justo después de `update`): Yazi, Lazygit, LazySSH y Lavat se instalan a través de él. Omitirlo en modo interactivo es seguro — esos pasos llaman a `ensure_brew` e instalan Homebrew como efecto secundario — y ese efecto secundario nunca toca la fila `brew`, que conserva el estado que le diste (`Omitido` si lo rechazaste, `No ejecutado` en modo automático).
- `dank` debe ejecutarse **antes** de `configs` y `zshrc`: `install_configs` sobrescribe `~/.config/niri`, y el config de Ghostty incluido trae `theme = dankcolors`, un tema creado por DMS.
- `zshrc` queda **al final**: sobrescribe `~/.zshrc`, descartando los retoques que el paso `plugins` hizo en `plugins=(` (el `.zshrc` incluido ya trae ambos plugins).

## Respaldos

Las configs sobrescritas nunca se borran en silencio: Niri, Neovim y Ghostty guardan copias `.bak-<epoch>`, y `.zshrc` guarda una copia `.zshrc.bak.<fecha>`. Los clones se despliegan de forma atómica — si el clon falla, la config existente no se toca. Los directorios padre que falten (p. ej. `~/.config` en una cuenta nueva) se crean primero como tu usuario, y un `Ctrl-C` en la ventana entre el respaldo y el swap final devuelve el respaldo a su sitio.

## Estructura del Repositorio

- `Fedora.sh`, `Cachyos.sh` — solo puntos de entrada: cargan `lib/common.sh`, aseguran la detección root/usuario, registran las 23 herramientas y abren el menú.
- `lib/common.sh` — toda la lógica compartida (menús, `install_*`/`check_*`, ayudantes por distro, más los ayudantes compartidos `brew_install`/`ensure_brew`/`brew_has_binary`/`cmd_available`, `ensure_node_for`/`npm_install_global` e `install_flatpak_app`). Se carga con `source`, nunca se ejecuta directo.
- `config_zsh/Fedora/.zshrc`, `config_zsh/Cachyos/.zshrc`, `config_ghostty/config` — payloads que el paso `zshrc` copia al home del usuario destino.
- `Doc/Fedora.md` / `Doc/Cachyos.md` — notas manuales paso a paso; pueden ir por detrás de los scripts, así que los scripts mandan.

## Verificar Cambios

```bash
bash -n Fedora.sh Cachyos.sh lib/common.sh config_zsh/Fedora/.zshrc config_zsh/Cachyos/.zshrc
```

Esa es la única comprobación segura (no hay tests ni linters instalados). No ejecutes los instaladores para "probar" — actualizan el sistema, ejecutan `chsh` y sobrescriben `~/.zshrc`.

---

## Idiomas

Leer esta documentación en:
- [Inglés](README.md)
