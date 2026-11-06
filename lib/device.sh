#!/usr/bin/env bash

DEFAULT_DEVICE_NAME="Redmi 9A"
DEFAULT_DEVICE_CODENAME="dandelion"
DEFAULT_DEFCONFIG="dandelion_defconfig"

confirm_redmi9a_base() {
  local codename_input source_type_input

  DEVICE_NAME="${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"

  read -rp "Codename del dispositivo [${DEVICE_CODENAME:-$DEFAULT_DEVICE_CODENAME}]: " codename_input
  codename_input="${codename_input,,}"
  DEVICE_CODENAME="${codename_input:-${DEVICE_CODENAME:-$DEFAULT_DEVICE_CODENAME}}"

  if [[ "$DEVICE_CODENAME" != "$DEFAULT_DEVICE_CODENAME" ]]; then
    echo "[WARN] Este flujo está optimizado para $DEFAULT_DEVICE_CODENAME (Redmi 9A)."
  fi

  read -rp "Versión Android objetivo (ej: 11): " android_input
  ANDROID_VERSION="${android_input:-${ANDROID_VERSION:-}}"

  read -rp "Versión MIUI base (ej: V12.5.6.0): " miui_input
  MIUI_BASE="${miui_input:-${MIUI_BASE:-}}"

  echo "Tipo de fuente kernel:"
  echo "1) kernel source oficial"
  echo "2) kernel stock modificado"
  read -rp "Opción [1/2]: " source_type_input

  case "$source_type_input" in
    1) KERNEL_SOURCE_TYPE="official" ;;
    2) KERNEL_SOURCE_TYPE="stock" ;;
    *)
      if [[ -n "${KERNEL_SOURCE_TYPE:-}" ]]; then
        echo "[WARN] Opción inválida. Manteniendo: $KERNEL_SOURCE_TYPE"
      else
        echo "[WARN] Opción inválida. Usando kernel source oficial."
        KERNEL_SOURCE_TYPE="official"
      fi
      ;;
  esac

  read -rp "Ruta local del source kernel (carpeta con Makefile): " source_path_input
  if [[ -n "${source_path_input// }" ]]; then
    KERNEL_SOURCE_PATH="$source_path_input"
  fi

  read -rp "Defconfig objetivo [${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}]: " defconfig_input
  KERNEL_DEFCONFIG="${defconfig_input:-${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}}"

  echo "[OK] Base confirmada: ${DEVICE_NAME} (${DEVICE_CODENAME})"
  echo "[OK] Android=${ANDROID_VERSION:-n/a} MIUI=${MIUI_BASE:-n/a} source=${KERNEL_SOURCE_TYPE:-n/a}"
}
