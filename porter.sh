#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_DIR/lib/checks.sh"
source "$PROJECT_DIR/lib/device.sh"
source "$PROJECT_DIR/lib/report.sh"

COMMAND="${1:-help}"
INPUT_DIR="$PROJECT_DIR/input"
OUTPUT_DIR="$PROJECT_DIR/output"
CONFIG_DIR="$PROJECT_DIR/configs"
CONFIG_FILE="$CONFIG_DIR/target.conf"

show_help() {
  echo "Android ROM Porter CLI"
  echo ""
  echo "Uso:"
  echo "  bash porter.sh init"
  echo "  bash porter.sh check-env"
  echo "  bash porter.sh menu"
  echo "  bash porter.sh select-platform --soc mtk|snapdragon"
  echo "  bash porter.sh show-platform"
  echo "  bash porter.sh scan --input ./input"
  echo "  bash porter.sh probe-device"
  echo "  bash porter.sh report"
}

parse_scan_args() {
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input) INPUT_DIR="$2"; shift 2 ;;
      *) echo "[WARN] Argumento desconocido: $1"; shift ;;
    esac
  done
}

save_platform() {
  local soc="$1"
  mkdir -p "$CONFIG_DIR"
  echo "SOC=$soc" > "$CONFIG_FILE"
  echo "[OK] Plataforma seleccionada: $soc"
  echo "[OK] Guardado en: $CONFIG_FILE"
}

select_platform() {
  local soc=""
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --soc) soc="$2"; shift 2 ;;
      *) echo "[WARN] Argumento desconocido: $1"; shift ;;
    esac
  done

  case "$soc" in
    mtk|snapdragon) save_platform "$soc" ;;
    *) echo "[ERROR] Debes indicar --soc mtk|snapdragon"; return 1 ;;
  esac
}

show_platform() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    echo "[OK] Plataforma actual: ${SOC:-no_definida}"
  else
    echo "[WARN] No hay plataforma configurada."
  fi
}

interactive_menu() {
  while true; do
    echo ""
    echo "==============================="
    echo "   Android ROM Porter - Menu   "
    echo "==============================="
    echo "1) Seleccionar plataforma (MTK)"
    echo "2) Seleccionar plataforma (Snapdragon)"
    echo "3) Ver plataforma actual"
    echo "4) Check entorno"
    echo "5) Scan ROM (./input)"
    echo "6) Probe device (adb)"
    echo "7) Generar reporte"
    echo "0) Salir"
    echo "-------------------------------"
    read -rp "Elige una opción: " opt

    case "$opt" in
      1) save_platform "mtk" ;;
      2) save_platform "snapdragon" ;;
      3) show_platform ;;
      4) check_environment || true ;;
      5) scan_rom_files "$INPUT_DIR" "$OUTPUT_DIR" "$CONFIG_FILE" || true ;;
      6) probe_device "$OUTPUT_DIR" || true ;;
      7) generate_report "$OUTPUT_DIR" "$CONFIG_FILE" ;;
      0) echo "Bye 👋"; break ;;
      *) echo "[WARN] Opción inválida." ;;
    esac
  done
}

case "$COMMAND" in
  init)
    mkdir -p "$PROJECT_DIR/input" "$PROJECT_DIR/output" "$PROJECT_DIR/lib" "$PROJECT_DIR/configs"
    echo "[OK] Estructura inicial creada."
    ;;
  check-env)
    check_environment
    ;;
  menu)
    interactive_menu
    ;;
  select-platform)
    select_platform "$@"
    ;;
  show-platform)
    show_platform
    ;;
  scan)
    parse_scan_args "$@"
    scan_rom_files "$INPUT_DIR" "$OUTPUT_DIR" "$CONFIG_FILE"
    ;;
  probe-device)
    probe_device "$OUTPUT_DIR"
    ;;
  report)
    generate_report "$OUTPUT_DIR" "$CONFIG_FILE"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "[ERROR] Comando desconocido: $COMMAND"
    show_help
    exit 1
    ;;
esac