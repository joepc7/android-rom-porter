#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

check_kernel_build_deps() {
  local deps missing dep
  deps=(git make gcc g++ flex bison bc openssl perl python3 cpio unzip lz4)
  missing=()

  for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
      missing+=("$dep")
    fi
  done

  if ((${#missing[@]} > 0)); then
    echo "[ERROR] Dependencias faltantes: ${missing[*]}"
    echo "[INFO] Instala dependencias y vuelve a intentar."
    return 1
  fi

  if command_exists clang; then
    echo "[OK] clang detectado: $(clang --version | head -n 1)"
  else
    echo "[WARN] clang no detectado. Algunos kernels MTK recientes lo requieren."
  fi

  echo "[OK] Dependencias base listas."
}

validate_kernel_source_path() {
  if [[ -z "${KERNEL_SOURCE_PATH:-}" ]]; then
    echo "[ERROR] Define KERNEL_SOURCE_PATH primero."
    return 1
  fi

  if [[ ! -d "$KERNEL_SOURCE_PATH" ]]; then
    echo "[ERROR] No existe carpeta: $KERNEL_SOURCE_PATH"
    return 1
  fi

  if [[ ! -f "$KERNEL_SOURCE_PATH/Makefile" ]]; then
    echo "[ERROR] No se encontró Makefile en: $KERNEL_SOURCE_PATH"
    return 1
  fi

  echo "[OK] Source kernel válido: $KERNEL_SOURCE_PATH"
}

validate_toolchain_path() {
  if [[ -z "${KERNEL_TOOLCHAIN_PATH:-}" ]]; then
    echo "[WARN] KERNEL_TOOLCHAIN_PATH vacío. Se usará toolchain del sistema."
    return 0
  fi

  if [[ ! -d "$KERNEL_TOOLCHAIN_PATH" ]]; then
    echo "[ERROR] No existe toolchain: $KERNEL_TOOLCHAIN_PATH"
    return 1
  fi

  echo "[OK] Toolchain detectada: $KERNEL_TOOLCHAIN_PATH"
}
