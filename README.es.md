# Bootstrapper Automatizado de Entorno de Desarrollo para Linux

Este repositorio contiene scripts Bash interactivos guiados por menús y perfiles de configuración para automatizar la preparación completa de un entorno de desarrollo en distribuciones modernas: **Fedora** y **CachyOS** (derivado de Arch Linux).

## Características Clave y Herramientas Instaladas

Los scripts automatizan la configuración de dieciséis (16) herramientas y características del sistema, listadas en el orden exacto en que aparecen en el menú y en la tabla de estado:

1. **Actualización del Sistema**: Refresca repositorios y realiza actualizaciones del sistema.
2. **Flatpak y Flathub**: Configura y registra el repositorio remoto de Flathub.
3. **Zsh y Oh My Zsh**: Cambia la shell por defecto de forma segura e instala `oh-my-zsh` de modo desatendido.
4. **Yazi**: Gestor de archivos para terminal ultrarrápido.
5. **Neovim y LazyVim**: Editor de texto moderno con plantilla inicial LazyVim.
6. **Lazygit**: Cliente de terminal para Git.
7. **Pokemon Colorscripts**: Despliegue de sprites Pokémon en la terminal.
8. **Gemini Copilot**: Entorno global para Node.js y la herramienta `@google/gemini-cli`.
9. **Brave Browser**: Navegador web seguro.
10. **Spotify**: Reproductor de música vía Flatpak.
11. **Obsidian**: Gestor de notas personales vía Flatpak.
12. **Dank Material Shell**: Script automatizado para la integración de temas y layouts.
13. **Antigravity CLI**: Instala la herramienta de línea de comandos Antigravity de Google.
14. **Configuraciones de Niri**: Clona configuraciones personalizadas para el gestor de ventanas en `~/.config/niri`.
15. **Plugins de Zsh**: Instalación e integración automática de `zsh-autosuggestions` y `zsh-syntax-highlighting`.
16. **`.zshrc` Personalizado y Ghostty**: Aplica un perfil de Zsh optimizado con alias y variables de entorno preconfiguradas, además del config de la terminal Ghostty en `~/.config/ghostty`. Este paso va al final porque sobrescribe `~/.zshrc`; el perfil depende de la distribución (`config_zsh/Fedora/.zshrc` o `config_zsh/Cachyos/.zshrc`).

---

## Uso

Ejecuta el script correspondiente a tu distribución de Linux. `sudo` es opcional: los scripts detectan si no son root y se re-ejecutan con `sudo` automáticamente.

### Para Sistemas Fedora
```bash
./Fedora.sh
```

### Para Sistemas CachyOS (Arch)
```bash
./Cachyos.sh
```

En Fedora, el script además instala sus prerrequisitos básicos (`git`, `curl`, `util-linux-user`) al arrancar.

### Modos de Ejecución
Al iniciar cualquiera de los scripts se muestra primero la tabla de estado y después un menú interactivo con las siguientes opciones:
1. **Todo automático:** Ejecuta secuencialmente los 16 pasos sin pausas.
2. **Interactivo:** Solicita confirmación `[s/N]` (`s` = sí) antes de ejecutar cada paso.
3. **Estado:** Muestra una tabla estructurada indicando qué herramientas ya están presentes o configuradas en el sistema.
4. **Salir:** Salida limpia del instalador.

Después de **Todo automático** e **Interactivo** se muestra un resumen de operaciones con uno de estos estados por herramienta: `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido`.

---

## Idiomas

Leer esta documentación en:
- [Inglés](README.md)
