# Bootstrapper Automatizado de Entorno de Desarrollo para Linux

Este repositorio contiene scripts Bash interactivos guiados por menús y perfiles de configuración para automatizar la preparación completa de un entorno de desarrollo en distribuciones modernas: **Fedora** y **CachyOS** (derivado de Arch Linux).

## Características Clave y Herramientas Instaladas

Los scripts automatizan la configuración de quince (15) herramientas y características del sistema:

### Categoría 1: Utilidades CLI, Shells y Editores
1. **Actualización del Sistema**: Refresca repositorios y realiza actualizaciones del sistema.
2. **Flatpak y Flathub**: Configura y registra el repositorio remoto de Flathub.
3. **Zsh y Oh My Zsh**: Cambia la shell por defecto de forma segura e instala `oh-my-zsh` de modo desatendido.
4. **Yazi**: Gestor de archivos para terminal ultrarrápido.
5. **Neovim y LazyVim**: Editor de texto moderno con plantilla inicial LazyVim.
6. **Lazygit**: Cliente de terminal para Git.
7. **Pokemon Colorscripts**: Despliegue de sprites Pokémon en la terminal.
8. **Gemini Copilot**: Entorno global para Node.js y la herramienta `@google/gemini-cli`.
9. **Plugins de Zsh**: Instalación e integración automática de `zsh-autosuggestions` y `zsh-syntax-highlighting`.
10. **`.zshrc` Personalizado**: Aplica un perfil de Zsh optimizado con alias y variables de entorno preconfiguradas.

### Categoría 2: Aplicaciones GUI y Configuraciones de Escritorio
11. **Brave Browser**: Navegador web seguro.
12. **Spotify**: Reproductor de música vía Flatpak.
13. **Obsidian**: Gestor de notas personales vía Flatpak.
14. **Dank Material Shell**: Script automatizado para la integración de temas y layouts.
15. **Configuraciones de Niri**: Clona configuraciones personalizadas para el gestor de ventanas en `~/.config/niri`.

---

## Uso

Ejecuta el script correspondiente usando `sudo` según tu distribución de Linux:

### Para Sistemas Fedora
```bash
sudo ./Fedora.sh
```

### Para Sistemas CachyOS (Arch)
```bash
sudo ./Cachyos.sh
```

### Modos de Ejecución
Al iniciar cualquiera de los scripts, se presentará un menú interactivo con las siguientes opciones:
1. **Todo automático:** Ejecuta secuencialmente los 15 pasos sin pausas.
2. **Interactivo:** Solicita confirmación `[y/N]` antes de ejecutar cada paso.
3. **Estado:** Muestra una tabla estructurada indicando qué herramientas ya están presentes o configuradas en el sistema.
4. **Salir:** Salida limpia del instalador.

---

## Idiomas

Leer esta documentación en:
- [Inglés](README.md)
