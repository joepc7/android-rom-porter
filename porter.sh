#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$PROJECT_DIR/configs"
CONFIG_FILE="$CONFIG_DIR/target.conf"

mkdir -p "$CONFIG_DIR"

WORK_DIR_DEFAULT="$PROJECT_DIR/workspace"
AOSP_PATH_DEFAULT=""
STOCK_PATH_DEFAULT=""

load_config() {
  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" || true
}

save_config() {
  cat > "$CONFIG_FILE" <<EOF
SOC=${SOC:-}
WORK_DIR=${WORK_DIR:-$WORK_DIR_DEFAULT}
AOSP_PATH=${AOSP_PATH:-$AOSP_PATH_DEFAULT}
STOCK_PATH=${STOCK_PATH:-$STOCK_PATH_DEFAULT}
EOF
}

show_help() {
  echo "Android ROM Porter - AOSP Build Assistant"
  echo ""
  echo "Uso:"
  echo "  bash porter.sh menu"
  echo "  bash porter.sh init-build"
  echo "  bash porter.sh show-config"
}

select_soc_menu() {
  echo "Selecciona plataforma:"
  echo "1) MTK"
  echo "2) Snapdragon"
  read -rp "Opción: " opt
  case "$opt" in
    1) SOC="mtk" ;;
    2) SOC="snapdragon" ;;
    *) echo "[WARN] Opción inválida"; return 1 ;;
  esac
  echo "[OK] SOC seleccionado: $SOC"
}

ask_work_dir() {
  read -rp "Ruta de trabajo (ej: /mnt/d/AndroidBuilds/proyecto1): " input
  [[ -z "${input// }" ]] && input="$WORK_DIR_DEFAULT"
  WORK_DIR="$input"
  mkdir -p "$WORK_DIR"/{aosp,stock,out,logs,tmp}
  echo "[OK] WORK_DIR: $WORK_DIR"
}

ask_rom_paths() {
  echo ""
  read -rp "Ruta ROM AOSP (zip/img/payload): " aosp_in
  if [[ ! -e "$aosp_in" ]]; then
    echo "[ERROR] No existe: $aosp_in"
    return 1
  fi
  AOSP_PATH="$aosp_in"

  read -rp "Ruta ROM STOCK (zip/img/payload): " stock_in
  if [[ ! -e "$stock_in" ]]; then
    echo "[ERROR] No existe: $stock_in"
    return 1
  fi
  STOCK_PATH="$stock_in"

  echo "[OK] AOSP:  $AOSP_PATH"
  echo "[OK] STOCK: $STOCK_PATH"
}

prepare_workspace() {
  mkdir -p "$WORK_DIR"/{aosp,stock,out,logs,tmp}
  cp -f "$AOSP_PATH" "$WORK_DIR/aosp/" 2>/dev/null || true
  cp -f "$STOCK_PATH" "$WORK_DIR/stock/" 2>/dev/null || true
  echo "[OK] Archivos copiados al workspace (si eran archivos)."
}

generate_plan() {
  local plan="$WORK_DIR/logs/build_plan.txt"
  cat > "$plan" <<EOF
=== AOSP Build/Port Plan ===
Fecha: $(date)
SOC: ${SOC:-no_definido}
WORK_DIR: ${WORK_DIR:-no_definido}
AOSP_PATH: ${AOSP_PATH:-no_definido}
STOCK_PATH: ${STOCK_PATH:-no_definido}

Estructura:
- $WORK_DIR/aosp
- $WORK_DIR/stock
- $WORK_DIR/out
- $WORK_DIR/logs
- $WORK_DIR/tmp

Siguiente fase sugerida:
1) Extraer AOSP y STOCK
2) Comparar particiones (boot/vendor_boot/dtbo/super)
3) Ajustar device tree + vendor blobs
4) Ejecutar build y guardar salida en out/
EOF
  echo "[OK] Plan generado: $plan"
}

show_config() {
  load_config
  echo "SOC=${SOC:-}"
  echo "WORK_DIR=${WORK_DIR:-$WORK_DIR_DEFAULT}"
  echo "AOSP_PATH=${AOSP_PATH:-}"
  echo "STOCK_PATH=${STOCK_PATH:-}"
}

init_build_flow() {
  load_config
  select_soc_menu
  ask_work_dir
  ask_rom_paths
  prepare_workspace
  save_config
  generate_plan
  echo "[OK] Flujo inicial completado."
}

menu() {
  load_config
  while true; do
    echo ""
    echo "=========== AOSP Assistant ==========="
    echo "1) Iniciar flujo completo (SOC + ruta + AOSP + STOCK)"
    echo "2) Seleccionar SOC"
    echo "3) Configurar ruta de trabajo"
    echo "4) Seleccionar ROM AOSP y STOCK"
    echo "5) Preparar workspace"
    echo "6) Ver configuración"
    echo "7) Generar plan"
    echo "0) Salir"
    echo "--------------------------------------"
    read -rp "Elige opción: " opt
    case "$opt" in
      1) init_build_flow ;;
      2) select_soc_menu; save_config ;;
      3) ask_work_dir; save_config ;;
      4) ask_rom_paths; save_config ;;
      5) prepare_workspace ;;
      6) show_config ;;
      7) generate_plan ;;
      0) break ;;
      *) echo "[WARN] Opción inválida" ;;
    esac
  done
}

case "${1:-menu}" in
  menu) menu ;;
  init-build) init_build_flow ;;
  show-config) show_config ;;
  help|--help|-h) show_help ;;
  *) echo "[ERROR] Comando desconocido: $1"; show_help; exit 1 ;;
esac