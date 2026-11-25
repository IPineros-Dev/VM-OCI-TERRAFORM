#!/usr/bin/env bash
set -euo pipefail

# Script manual opcional para actualizar el sitio web en una VM ya desplegada
REPO_URL="${1:-https://github.com/adanbeltran/ecored-estatica.git}"
WEB_ROOT="${2:-/var/www/ecored-estatica}"

if [ -d "$WEB_ROOT/.git" ]; then
  git -C "$WEB_ROOT" pull --ff-only
else
  rm -rf "$WEB_ROOT"
  git clone "$REPO_URL" "$WEB_ROOT"
fi

chown -R ubuntu:www-data "$WEB_ROOT"
chmod -R u=rwX,g=rX,o=rX "$WEB_ROOT"
systemctl reload nginx

echo "Sitio actualizado correctamente en $WEB_ROOT"
