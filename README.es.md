# Preparación de un entorno de desarrollo en Linux

Scripts Bash interactivos para configurar **Fedora** y **CachyOS**. Cada script registra 23 pasos en el orden indicado aquí y en el menú.

## Pasos de instalación

1. **Actualización del sistema** — `dnf upgrade --refresh` o `pacman -Syu`.
2. **Homebrew** — instala Linuxbrew como tu usuario. Yazi, Lazygit, LazySSH y Lavat lo usan; si hace falta, lo instalan automáticamente. Para cambiar el prefijo: `BREW_PREFIX=/ruta`.
3. **Flatpak** — instala Flatpak y añade Flathub para tu usuario. Spotify y Obsidian lo usan automáticamente.
4. **Zsh y Oh My Zsh** — instala Zsh, cambia la shell predeterminada e instala Oh My Zsh.
5. **Yazi** — gestor de archivos para terminal, instalado con Homebrew.
6. **Neovim y LazyVim** — incluye dependencias (`fd-find` en Fedora, `fd` en CachyOS) y respalda la configuración existente.
7. **Lazygit** — cliente de Git para terminal, instalado con Homebrew.
8. **Pokemon Colorscripts** — muestra sprites Pokémon en la terminal.
9. **Node.js y npm** — instala ambos y configura los paquetes globales en `~/.npm-global`, sin `sudo`.
10. **Gemini CLI** — instalación global con npm; instala Node.js/npm si omitiste el paso 9.
11. **GitHub Copilot CLI** — instalador oficial; no requiere Node.js.
12. **Repomix** — instalación global con npm; instala Node.js/npm si omitiste el paso 9.
13. **LazySSH** — gestor SSH para terminal, instalado con Homebrew.
14. **Lavat** — simulación de lámpara de lava para terminal, instalada con Homebrew.
15. **Brave Browser** — instalador oficial.
16. **Spotify** — Flatpak instalado para tu usuario.
17. **Obsidian** — Flatpak instalado para tu usuario.
18. **Dank Material Shell** — configuración interactiva de compositor y terminal; se ejecuta como tu usuario.
19. **Antigravity CLI** — se instala como tu usuario.
20. **OpenCode** — se instala como tu usuario.
21. **Configuración de Niri** — despliega la configuración y pide confirmación antes de reemplazar una existente.
22. **Plugins de Zsh** — instala autosuggestions y syntax highlighting.
23. **Configuración de Zsh y Ghostty** — despliega perfiles específicos de la distro y configura el PATH.

## Requisitos y uso

- Requiere Fedora o CachyOS, `git` y `curl`. Los scripts instalan sus prerrequisitos iniciales y rechazan otras distribuciones.
- Ejecuta el script desde tu **sesión normal de usuario**, no desde una shell root. `sudo` es opcional: el script se vuelve a ejecutar como root conservando tu usuario. La ejecución como root puro se rechaza para evitar instalar configuraciones en `/root`.

```bash
./Fedora.sh    # Fedora
./Cachyos.sh   # CachyOS
```

El menú ofrece:
- **Todo automático** — ejecuta todos los pasos. Dank Material Shell sigue siendo interactivo; Niri pide confirmación si ya existe una configuración.
- **Interactivo** — pregunta antes de cada paso; `a` acepta los restantes. Las preguntas internas se mantienen.
- **Estado** — muestra qué herramientas están instaladas.
- **Salir** — termina.

El resumen muestra `Éxito`, `Éxito (Ya existía)`, `Error`, `Omitido` o `No ejecutado`.

## Orden y respaldos

- Homebrew va al principio porque cuatro herramientas dependen de él.
- Ejecuta Dank Material Shell antes de configurar Niri y Ghostty; proporciona el tema `dankcolors`.
- La configuración de Zsh va al final porque sobrescribe `~/.zshrc`; los perfiles incluidos ya contienen ambos plugins y las entradas necesarias del PATH.
- Las configuraciones existentes de Niri, Neovim, Ghostty y Zsh se respaldan. Los clones se despliegan de forma atómica: si falla la clonación, se conserva la configuración actual.

## Repositorio y verificación segura

- `Fedora.sh` y `Cachyos.sh` son puntos de entrada; la lógica compartida está en `lib/common.sh`.
- `config_zsh/` y `config_ghostty/` contienen los perfiles desplegados. `Doc/` contiene instrucciones antiguas; prevalecen los scripts.
- Comprobación de sintaxis: `bash -n Fedora.sh Cachyos.sh lib/common.sh config_zsh/Fedora/.zshrc config_zsh/Cachyos/.zshrc`
- **No ejecutes los instaladores para probar cambios:** modifican el sistema, ejecutan `chsh` y sobrescriben archivos de configuración. No hay pruebas automatizadas ni linters.

---

## Idiomas

- [Inglés](README.md)

## Licencia

- [Licencia MIT](LICENSE) 