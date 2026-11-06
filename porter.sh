#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$PROJECT_DIR/configs"
CONFIG_FILE="$CONFIG_DIR/target.conf"

LIB_DIR="$PROJECT_DIR/lib"
# shellcheck source=lib/device.sh
source "$LIB_DIR/device.sh"
# shellcheck source=lib/checks.sh
source "$LIB_DIR/checks.sh"
# shellcheck source=lib/report.sh
source "$LIB_DIR/report.sh"
# shellcheck source=lib/dandelionx.sh
source "$LIB_DIR/dandelionx.sh"

mkdir -p "$CONFIG_DIR"

WORK_DIR_DEFAULT="$PROJECT_DIR/workspace"
AOSP_PATH_DEFAULT=""
STOCK_PATH_DEFAULT=""
KERNEL_OUT_DEFAULT=""

load_config() {
  local tmp_cfg
  [[ -f "$CONFIG_FILE" ]] || return 0

  tmp_cfg="$(mktemp)"
  grep -E '^(SOC|WORK_DIR|AOSP_PATH|STOCK_PATH|DEVICE_NAME|DEVICE_CODENAME|ANDROID_VERSION|MIUI_BASE|KERNEL_SOURCE_TYPE|KERNEL_SOURCE_PATH|KERNEL_DEFCONFIG|KERNEL_TOOLCHAIN_PATH|KERNEL_WORK_BRANCH|KERNEL_OUT_DIR|DX_PROFILE_NAME|DX_TAGLINE|DX_DEVICE|DX_SOC|DX_RAM|DX_KERNEL_VERSION|DX_ANDROID_TARGETS)=' "$CONFIG_FILE" > "$tmp_cfg" || true
  # shellcheck source=/dev/null
  source "$tmp_cfg" || true
  rm -f "$tmp_cfg"
}

save_config() {
  {
    printf 'SOC=%q\n' "${SOC:-}"
    printf 'WORK_DIR=%q\n' "${WORK_DIR:-$WORK_DIR_DEFAULT}"
    printf 'AOSP_PATH=%q\n' "${AOSP_PATH:-$AOSP_PATH_DEFAULT}"
    printf 'STOCK_PATH=%q\n' "${STOCK_PATH:-$STOCK_PATH_DEFAULT}"
    printf 'DEVICE_NAME=%q\n' "${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"
    printf 'DEVICE_CODENAME=%q\n' "${DEVICE_CODENAME:-$DEFAULT_DEVICE_CODENAME}"
    printf 'ANDROID_VERSION=%q\n' "${ANDROID_VERSION:-}"
    printf 'MIUI_BASE=%q\n' "${MIUI_BASE:-}"
    printf 'KERNEL_SOURCE_TYPE=%q\n' "${KERNEL_SOURCE_TYPE:-official}"
    printf 'KERNEL_SOURCE_PATH=%q\n' "${KERNEL_SOURCE_PATH:-}"
    printf 'KERNEL_DEFCONFIG=%q\n' "${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}"
    printf 'KERNEL_TOOLCHAIN_PATH=%q\n' "${KERNEL_TOOLCHAIN_PATH:-}"
    printf 'KERNEL_WORK_BRANCH=%q\n' "${KERNEL_WORK_BRANCH:-}"
    printf 'KERNEL_OUT_DIR=%q\n' "${KERNEL_OUT_DIR:-$KERNEL_OUT_DEFAULT}"
    printf 'DX_PROFILE_NAME=%q\n' "${DX_PROFILE_NAME:-$DX_DEFAULT_NAME}"
    printf 'DX_TAGLINE=%q\n' "${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}"
    printf 'DX_DEVICE=%q\n' "${DX_DEVICE:-$DX_DEFAULT_DEVICE}"
    printf 'DX_SOC=%q\n' "${DX_SOC:-$DX_DEFAULT_SOC}"
    printf 'DX_RAM=%q\n' "${DX_RAM:-$DX_DEFAULT_RAM}"
    printf 'DX_KERNEL_VERSION=%q\n' "${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}"
    printf 'DX_ANDROID_TARGETS=%q\n' "${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"
  } > "$CONFIG_FILE"
}

show_help() {
  echo "Android ROM Porter - AOSP/Kernel Build Assistant"
  echo ""
  echo "Uso:"
  echo "  bash porter.sh menu"
  echo "  bash porter.sh init-build"
  echo "  bash porter.sh kernel-build"
  echo "  bash porter.sh dandelionx-init"
  echo "  bash porter.sh dandelionx-build-matrix"
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
  [[ -z "${KERNEL_OUT_DIR:-}" ]] && KERNEL_OUT_DIR="$WORK_DIR/out/kernel"
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
  cat > "$plan" <<EOF_PLAN
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
EOF_PLAN
  echo "[OK] Plan generado: $plan"
}

confirm_device_base_flow() {
  confirm_redmi9a_base
  if [[ -n "${KERNEL_SOURCE_PATH:-}" ]] && [[ ! -d "$KERNEL_SOURCE_PATH" ]]; then
    echo "[WARN] KERNEL_SOURCE_PATH no existe aún: $KERNEL_SOURCE_PATH"
  fi
  save_config
}

configure_kernel_environment() {
  load_config
  check_kernel_build_deps

  read -rp "Ruta toolchain (vacío = usar sistema): " toolchain_input
  if [[ -n "${toolchain_input// }" ]]; then
    KERNEL_TOOLCHAIN_PATH="$toolchain_input"
  fi

  validate_toolchain_path

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  mkdir -p "$WORK_DIR"/{out,logs,tmp}
  KERNEL_OUT_DIR="${KERNEL_OUT_DIR:-$WORK_DIR/out/kernel}"
  mkdir -p "$KERNEL_OUT_DIR"

  echo "[OK] Entorno de compilación listo."
  save_config
}

prepare_kernel_source() {
  load_config
  validate_kernel_source_path

  if [[ -z "${KERNEL_WORK_BRANCH:-}" ]]; then
    KERNEL_WORK_BRANCH="dandelion-kernel-$(date +%Y%m%d-%H%M)"
  fi

  if [[ -d "$KERNEL_SOURCE_PATH/.git" ]]; then
    git -C "$KERNEL_SOURCE_PATH" checkout -B "$KERNEL_WORK_BRANCH"
    echo "[OK] Branch kernel preparada: $KERNEL_WORK_BRANCH"
  else
    echo "[WARN] KERNEL_SOURCE_PATH no es repo git; se omite creación de branch."
  fi

  save_config
}

kernel_make_env_prefix() {
  local prefix=""
  if [[ -n "${KERNEL_TOOLCHAIN_PATH:-}" ]]; then
    prefix="PATH=$KERNEL_TOOLCHAIN_PATH/bin:$PATH"
  fi
  echo "$prefix"
}

configure_kernel_defconfig() {
  load_config
  validate_kernel_source_path

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  KERNEL_OUT_DIR="${KERNEL_OUT_DIR:-$WORK_DIR/out/kernel}"
  mkdir -p "$KERNEL_OUT_DIR"

  local env_prefix
  env_prefix="$(kernel_make_env_prefix)"

  echo "[INFO] Ejecutando defconfig: ${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}"
  if [[ -n "$env_prefix" ]]; then
    eval "$env_prefix make -C \"$KERNEL_SOURCE_PATH\" O=\"$KERNEL_OUT_DIR\" ARCH=arm64 \"${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}\""
  else
    make -C "$KERNEL_SOURCE_PATH" O="$KERNEL_OUT_DIR" ARCH=arm64 "${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}"
  fi

  echo "[OK] Defconfig aplicada sin errores."
  save_config
}

build_kernel() {
  load_config
  validate_kernel_source_path

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  KERNEL_OUT_DIR="${KERNEL_OUT_DIR:-$WORK_DIR/out/kernel}"
  mkdir -p "$KERNEL_OUT_DIR"

  local jobs env_prefix
  jobs="$(nproc)"
  env_prefix="$(kernel_make_env_prefix)"

  echo "[INFO] Compilando kernel y módulos con -j$jobs"
  if [[ -n "$env_prefix" ]]; then
    eval "$env_prefix make -C \"$KERNEL_SOURCE_PATH\" O=\"$KERNEL_OUT_DIR\" ARCH=arm64 -j$jobs"
    eval "$env_prefix make -C \"$KERNEL_SOURCE_PATH\" O=\"$KERNEL_OUT_DIR\" ARCH=arm64 modules -j$jobs"
  else
    make -C "$KERNEL_SOURCE_PATH" O="$KERNEL_OUT_DIR" ARCH=arm64 -j"$jobs"
    make -C "$KERNEL_SOURCE_PATH" O="$KERNEL_OUT_DIR" ARCH=arm64 modules -j"$jobs"
  fi

  echo "[OK] Compilación finalizada."
}

package_kernel_images() {
  load_config

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  KERNEL_OUT_DIR="${KERNEL_OUT_DIR:-$WORK_DIR/out/kernel}"
  local package_dir image_path dtbo_guess
  package_dir="$WORK_DIR/out/package"
  image_path="$KERNEL_OUT_DIR/arch/arm64/boot/Image.gz-dtb"
  dtbo_guess="$KERNEL_OUT_DIR/arch/arm64/boot/dtbo.img"

  mkdir -p "$package_dir"

  if [[ ! -f "$image_path" ]]; then
    echo "[ERROR] No existe $image_path. Ejecuta compile primero."
    return 1
  fi

  cp -f "$image_path" "$package_dir/"
  if [[ -f "$dtbo_guess" ]]; then
    cp -f "$dtbo_guess" "$package_dir/"
  fi

  cat > "$package_dir/pack_commands.sh" <<EOF_PACK
#!/usr/bin/env bash
set -euo pipefail

# Edita estas rutas según tu caso antes de ejecutar.
KERNEL_IMG="${package_dir}/Image.gz-dtb"
RAMDISK="<ruta_ramdisk_original.cpio.gz>"
DTB="<ruta_dtb_o_dtb.img>"
DTBO="${package_dir}/dtbo.img"

# Android 10 suele usar boot.img clásico.
# Android 11/12 puede requerir vendor_boot.img.
# Requiere mkbootimg + unpack de imágenes stock para conservar headers/base/pagesize.

echo "Genera boot.img/vendor_boot.img con parámetros de tu imagen stock."
EOF_PACK
  chmod +x "$package_dir/pack_commands.sh"

  echo "[OK] Artefactos copiados a: $package_dir"
  echo "[INFO] Revisa y completa: $package_dir/pack_commands.sh"
}

generate_flash_test_checklist() {
  load_config

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  local checklist
  checklist="$WORK_DIR/logs/flash_test_checklist.txt"

  cat > "$checklist" <<EOF_CHECK
=== Flash + Validation Checklist (Redmi 9A) ===
Fecha: $(date)

1) Flasheo de prueba:
   - fastboot flash boot <boot.img>
   - fastboot flash vendor_boot <vendor_boot.img> (si aplica)
   - fastboot reboot

2) Limpieza/caches:
   - Wipe dalvik/cache desde recovery si hay bootloop.

3) Validación funcional:
   - Arranque completo
   - Pantalla táctil
   - Red móvil/WiFi/Bluetooth
   - Audio (speaker/mic)
   - Sensores
   - Carga USB/batería

4) Depuración si no inicia:
   - adb shell dmesg > dmesg.txt
   - adb shell cat /proc/last_kmsg > last_kmsg.txt (si existe)
   - Revisar cambios mínimos y recompilar.
EOF_CHECK

  echo "[OK] Checklist generado: $checklist"
}

kernel_build_flow() {
  confirm_device_base_flow
  configure_kernel_environment
  prepare_kernel_source
  configure_kernel_defconfig
  build_kernel
  package_kernel_images
  generate_flash_test_checklist
  generate_kernel_build_report
  echo "[OK] Flujo kernel completado."
}

dandelionx_init_flow() {
  load_config

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi
  mkdir -p "$WORK_DIR"/{out,logs,tmp}

  setup_dandelionx_profile
  init_dandelionx_workspace

  save_config
}

dandelionx_build_matrix_flow() {
  load_config
  check_kernel_build_deps
  validate_kernel_source_path

  if [[ -z "${WORK_DIR:-}" ]]; then
    WORK_DIR="$WORK_DIR_DEFAULT"
  fi

  local matrix_script
  matrix_script="$WORK_DIR/dandelionx/matrix/build-matrix.sh"

  if [[ ! -x "$matrix_script" ]]; then
    echo "[INFO] No existe build matrix script, inicializando Dandelion X primero."
    init_dandelionx_workspace
  fi

  if [[ ! -x "$matrix_script" ]]; then
    echo "[ERROR] No se pudo preparar $matrix_script"
    return 1
  fi

  export WORK_DIR KERNEL_SOURCE_PATH KERNEL_DEFCONFIG KERNEL_TOOLCHAIN_PATH DX_ANDROID_TARGETS
  "$matrix_script"
}

show_config() {
  load_config
  echo "SOC=${SOC:-}"
  echo "WORK_DIR=${WORK_DIR:-$WORK_DIR_DEFAULT}"
  echo "AOSP_PATH=${AOSP_PATH:-}"
  echo "STOCK_PATH=${STOCK_PATH:-}"
  echo "DEVICE_NAME=${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"
  echo "DEVICE_CODENAME=${DEVICE_CODENAME:-$DEFAULT_DEVICE_CODENAME}"
  echo "ANDROID_VERSION=${ANDROID_VERSION:-}"
  echo "MIUI_BASE=${MIUI_BASE:-}"
  echo "KERNEL_SOURCE_TYPE=${KERNEL_SOURCE_TYPE:-official}"
  echo "KERNEL_SOURCE_PATH=${KERNEL_SOURCE_PATH:-}"
  echo "KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-$DEFAULT_DEFCONFIG}"
  echo "KERNEL_TOOLCHAIN_PATH=${KERNEL_TOOLCHAIN_PATH:-}"
  echo "KERNEL_WORK_BRANCH=${KERNEL_WORK_BRANCH:-}"
  echo "KERNEL_OUT_DIR=${KERNEL_OUT_DIR:-$KERNEL_OUT_DEFAULT}"
  echo "DX_PROFILE_NAME=${DX_PROFILE_NAME:-$DX_DEFAULT_NAME}"
  echo "DX_TAGLINE=${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}"
  echo "DX_DEVICE=${DX_DEVICE:-$DX_DEFAULT_DEVICE}"
  echo "DX_SOC=${DX_SOC:-$DX_DEFAULT_SOC}"
  echo "DX_RAM=${DX_RAM:-$DX_DEFAULT_RAM}"
  echo "DX_KERNEL_VERSION=${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}"
  echo "DX_ANDROID_TARGETS=${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"
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
    echo "=========== AOSP + Kernel Assistant ==========="
    echo "1) Iniciar flujo ROM (SOC + ruta + AOSP + STOCK)"
    echo "2) Seleccionar SOC"
    echo "3) Configurar ruta de trabajo"
    echo "4) Seleccionar ROM AOSP y STOCK"
    echo "5) Preparar workspace"
    echo "6) Ver configuración"
    echo "7) Generar plan ROM"
    echo "-----------------------------------------------"
    echo "8) Confirmar base Redmi 9A"
    echo "9) Preparar entorno de compilación kernel"
    echo "10) Preparar source kernel (branch limpia)"
    echo "11) Ejecutar defconfig"
    echo "12) Compilar kernel + módulos"
    echo "13) Empaquetado base (artefactos + plantilla)"
    echo "14) Generar checklist flash/depuración"
    echo "15) Ejecutar flujo kernel completo"
    echo "16) Generar reporte de kernel"
    echo "17) Inicializar DANDELION X EXTREME"
    echo "18) Ejecutar build matrix Android (A15-A17)"
    echo "0) Salir"
    echo "-----------------------------------------------"
    read -rp "Elige opción: " opt
    case "$opt" in
      1) init_build_flow ;;
      2) select_soc_menu; save_config ;;
      3) ask_work_dir; save_config ;;
      4) ask_rom_paths; save_config ;;
      5) prepare_workspace ;;
      6) show_config ;;
      7) generate_plan ;;
      8) confirm_device_base_flow ;;
      9) configure_kernel_environment ;;
      10) prepare_kernel_source ;;
      11) configure_kernel_defconfig ;;
      12) build_kernel ;;
      13) package_kernel_images ;;
      14) generate_flash_test_checklist ;;
      15) kernel_build_flow ;;
      16) generate_kernel_build_report ;;
      17) dandelionx_init_flow ;;
      18) dandelionx_build_matrix_flow ;;
      0) break ;;
      *) echo "[WARN] Opción inválida" ;;
    esac
  done
}

case "${1:-menu}" in
  menu) menu ;;
  init-build) init_build_flow ;;
  kernel-build) kernel_build_flow ;;
  dandelionx-init) dandelionx_init_flow ;;
  dandelionx-build-matrix) dandelionx_build_matrix_flow ;;
  show-config) show_config ;;
  help|--help|-h) show_help ;;
  *) echo "[ERROR] Comando desconocido: $1"; show_help; exit 1 ;;
esac
