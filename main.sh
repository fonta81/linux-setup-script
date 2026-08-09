#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script requiere permisos de administrador."
  exec sudo "$0" "$@"
fi

# un script para facilitar la instalacion de mis herramientas fedora herramientas: [update, zsh-ohmyzsh, yazi, nvin-lazyvil, lazygit, Pokemon, dmk, copilot-gemini, brave, Spotify, flatpack]
# update es para actualizar el sistema x si acaso
