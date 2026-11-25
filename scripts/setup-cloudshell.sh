#!/usr/bin/env bash
set -euo pipefail

# Script auxiliar para preparar el proyecto en OCI Cloud Shell (Linux)
# Uso opcional:
#   bash scripts/setup-cloudshell.sh
#   bash scripts/setup-cloudshell.sh ~/mi-llave-privada.pem

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYS_DIR="$PROJECT_DIR/keys"
TARGET_API_KEY="$KEYS_DIR/oci_api_key.pem"
SSH_KEY_PATH="$KEYS_DIR/oci_vm_key"

mkdir -p "$KEYS_DIR"

echo "================================================================"
echo "  Preparación del entorno en OCI Cloud Shell"
echo "================================================================"

# 1. Verificar herramientas requeridas
echo ""
echo "[1/4] Verificando herramientas disponibles..."
for BIN in terraform git ssh-keygen; do
  if command -v "$BIN" >/dev/null 2>&1; then
    echo "  OK: $BIN ($(command -v "$BIN"))"
  else
    echo "  FALTA: $BIN no encontrado en PATH."
    exit 1
  fi
done
terraform version | head -n 1

# 2. Cargar y asegurar la API Private Key (.pem) subida a OCI Cloud Shell
echo ""
echo "[2/4] Configurando la API Private Key (.pem)..."
PROVIDED_KEY="${1:-}"

if [ -n "$PROVIDED_KEY" ]; then
  if [ ! -f "$PROVIDED_KEY" ]; then
    echo "  ERROR: No se encontró el archivo indicado: $PROVIDED_KEY"
    exit 1
  fi
  cp "$PROVIDED_KEY" "$TARGET_API_KEY"
  chmod 600 "$TARGET_API_KEY"
  echo "  Llave copiada a $TARGET_API_KEY con permisos 600."
elif [ -f "$TARGET_API_KEY" ]; then
  chmod 600 "$TARGET_API_KEY"
  echo "  Ya existe $TARGET_API_KEY (permisos verificados en 600)."
else
  mapfile -t FOUND_PEMS < <(find "$HOME" -maxdepth 2 -type f -name "*.pem" 2>/dev/null | sort)

  if [ "${#FOUND_PEMS[@]}" -eq 0 ]; then
    echo "  No se detectó ningún archivo .pem en $HOME."
    echo "  Sube tu Private Key usando el menú de OCI Cloud Shell (icono engranaje -> Upload),"
    echo "  y luego vuelve a ejecutar: bash scripts/setup-cloudshell.sh ~/tu_llave.pem"
  elif [ "${#FOUND_PEMS[@]}" -eq 1 ]; then
    echo "  Se encontró el archivo: ${FOUND_PEMS[0]}"
    read -r -p "  ¿Copiar este archivo a ./keys/oci_api_key.pem? [S/n]: " CONFIRM
    if [[ "${CONFIRM:-S}" =~ ^[SsYy]$ ]]; then
      cp "${FOUND_PEMS[0]}" "$TARGET_API_KEY"
      chmod 600 "$TARGET_API_KEY"
      echo "  Llave copiada a $TARGET_API_KEY con permisos 600."
    fi
  else
    echo "  Se encontraron múltiples archivos .pem en $HOME:"
    for i in "${!FOUND_PEMS[@]}"; do
      echo "    [$((i + 1))] ${FOUND_PEMS[$i]}"
    done
    read -r -p "  Elige el número de tu OCI API Private Key (o Enter para omitir): " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#FOUND_PEMS[@]}" ]; then
      SELECTED="${FOUND_PEMS[$((CHOICE - 1))]}"
      cp "$SELECTED" "$TARGET_API_KEY"
      chmod 600 "$TARGET_API_KEY"
      echo "  Llave copiada a $TARGET_API_KEY con permisos 600."
    fi
  fi
fi

# 3. Generar par de llaves SSH ed25519 si no existe
echo ""
echo "[3/4] Configurando llaves SSH para la VM..."
if [ -f "$SSH_KEY_PATH" ] && [ -f "${SSH_KEY_PATH}.pub" ]; then
  chmod 600 "$SSH_KEY_PATH"
  echo "  Ya existe el par SSH en $SSH_KEY_PATH (permisos verificados en 600)."
else
  ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "oci-vm-automatic"
  chmod 600 "$SSH_KEY_PATH"
  echo "  Par SSH generado en $SSH_KEY_PATH y ${SSH_KEY_PATH}.pub."
fi

# 4. Crear terraform.tfvars desde la plantilla si no existe
echo ""
echo "[4/4] Preparando archivo terraform.tfvars..."
if [ ! -f "$PROJECT_DIR/terraform.tfvars" ]; then
  cp "$PROJECT_DIR/terraform.tfvars.example" "$PROJECT_DIR/terraform.tfvars"
  echo "  Creado $PROJECT_DIR/terraform.tfvars desde terraform.tfvars.example."
  echo "  Edítalo con: nano terraform.tfvars"
else
  echo "  Ya existe $PROJECT_DIR/terraform.tfvars (no se sobrescribió)."
fi

echo ""
echo "================================================================"
echo "  Siguiente paso:"
echo "  1. Completa tus OCIDs y región en terraform.tfvars"
echo "  2. Ejecuta: terraform init && terraform plan && terraform apply"
echo "================================================================"
