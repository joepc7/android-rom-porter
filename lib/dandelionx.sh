#!/usr/bin/env bash

DX_DEFAULT_NAME="DANDELION X EXTREME"
DX_DEFAULT_TAGLINE="Adaptive Performance Intelligence"
DX_DEFAULT_DEVICE="Redmi 9A"
DX_DEFAULT_SOC="Helio G25"
DX_DEFAULT_RAM="2 GB"
DX_DEFAULT_KERNEL="Linux 4.19.325"
DX_DEFAULT_ANDROID_TARGETS="a15,a16,a17"

canonical_android_target() {
  local raw
  raw="${1,,}"
  raw="${raw// /}"

  case "$raw" in
    15|a15) echo "a15" ;;
    16|a16) echo "a16" ;;
    17|a17) echo "a17" ;;
    *) return 1 ;;
  esac
}

parse_android_targets() {
  local raw token normalized
  raw="${1:-$DX_DEFAULT_ANDROID_TARGETS}"
  raw="${raw//;/,}"
  raw="${raw// /,}"

  local -a tokens
  IFS=',' read -r -a tokens <<< "$raw"

  DX_PARSED_TARGETS=()
  for token in "${tokens[@]}"; do
    [[ -z "$token" ]] && continue
    if normalized="$(canonical_android_target "$token")"; then
      if [[ " ${DX_PARSED_TARGETS[*]} " != *" $normalized "* ]]; then
        DX_PARSED_TARGETS+=("$normalized")
      fi
    fi
  done

  if ((${#DX_PARSED_TARGETS[@]} == 0)); then
    DX_PARSED_TARGETS=(a15 a16 a17)
  fi
}

target_stability_tier() {
  case "$1" in
    a15|a16) echo "stable" ;;
    a17) echo "experimental" ;;
    *) echo "unknown" ;;
  esac
}

setup_dandelionx_profile() {
  local input

  read -rp "Nombre del perfil [${DX_PROFILE_NAME:-$DX_DEFAULT_NAME}]: " input
  DX_PROFILE_NAME="${input:-${DX_PROFILE_NAME:-$DX_DEFAULT_NAME}}"

  read -rp "Tagline [${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}]: " input
  DX_TAGLINE="${input:-${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}}"

  read -rp "Dispositivo [${DX_DEVICE:-$DX_DEFAULT_DEVICE}]: " input
  DX_DEVICE="${input:-${DX_DEVICE:-$DX_DEFAULT_DEVICE}}"

  read -rp "SoC [${DX_SOC:-$DX_DEFAULT_SOC}]: " input
  DX_SOC="${input:-${DX_SOC:-$DX_DEFAULT_SOC}}"

  read -rp "RAM [${DX_RAM:-$DX_DEFAULT_RAM}]: " input
  DX_RAM="${input:-${DX_RAM:-$DX_DEFAULT_RAM}}"

  read -rp "Kernel [${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}]: " input
  DX_KERNEL_VERSION="${input:-${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}}"

  read -rp "Targets Android (a15,a16,a17) [${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}]: " input
  DX_ANDROID_TARGETS="${input:-${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}}"

  parse_android_targets "$DX_ANDROID_TARGETS"
  DX_ANDROID_TARGETS="$(IFS=,; echo "${DX_PARSED_TARGETS[*]}")"

  echo "[OK] Perfil Dandelion X configurado para: $DX_ANDROID_TARGETS"
}

write_dandelionx_layers() {
  local layer_file="$1"
  cat > "$layer_file" <<EOF_LAYERS
01|Dandelion AI Engine|Inteligencia autónoma ligera con reglas adaptativas y aprendizaje de patrones.
02|Context Engine|Seguimiento de app en primer plano, actividad y contexto de uso.
03|Resource Engine|Control de CPU, RAM e I/O según carga real.
04|Safety Controller|Protección térmica, límites y recuperación.
05|Kernel Interface|Integración Linux 4.19.325 + KernelSU sin romper límites OEM.
EOF_LAYERS
}

write_dandelionx_engines() {
  local engines_dir="$1"

  cat > "$engines_dir/01-x-cpu-engine.conf" <<'EOF_CPU'
name=X-CPU Engine
enabled=1
goal=Ajuste adaptativo de frecuencias
rules=priorizar_foreground,respuesta_rapida,respetar_limites_oem
EOF_CPU

  cat > "$engines_dir/02-hyperram.conf" <<'EOF_RAM'
name=HyperRAM
enabled=1
goal=Gestion de memoria para 2 GB
rules=monitor_presion,zram_si_disponible,proteger_apps_clave,limpieza_cache_controlada
EOF_RAM

  cat > "$engines_dir/03-gpu-intelligence.conf" <<'EOF_GPU'
name=GPU Intelligence
enabled=1
goal=Balance grafico compatible con PowerVR
rules=monitor_carga_gpu,identificar_apps_exigentes,evitar_ajustes_no_soportados
EOF_GPU

  cat > "$engines_dir/04-io-accelerator.conf" <<'EOF_IO'
name=I/O Accelerator
enabled=1
goal=Reducir latencia de almacenamiento
rules=priorizar_io_activo,optimizar_lectura_escritura,reducir_io_background
EOF_IO

  cat > "$engines_dir/05-thermal-guardian.conf" <<'EOF_THERMAL'
name=Thermal Guardian
enabled=1
goal=Control termico preventivo
rules=vigilar_sensores,detectar_tendencias,reducir_carga_preventiva,mantener_protecciones_oem
EOF_THERMAL

  cat > "$engines_dir/06-touch-response.conf" <<'EOF_TOUCH'
name=Touch & Response
enabled=1
goal=Mejorar respuesta durante interaccion
rules=detectar_touch,boost_temporal,reducir_trabajo_no_critico
EOF_TOUCH

  cat > "$engines_dir/07-learning-engine.conf" <<'EOF_LEARN'
name=Learning Engine
enabled=1
goal=Aprendizaje local sin Internet
rules=aprender_patrones,identificar_apps_frecuentes,evaluar_resultados,adaptar_estrategias
EOF_LEARN
}

generate_dandelionx_blueprint() {
  local blueprint="$1"
  cat > "$blueprint" <<EOF_BLUE
=== ${DX_PROFILE_NAME:-$DX_DEFAULT_NAME} ===
${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}

Hardware objetivo:
- Dispositivo: ${DX_DEVICE:-$DX_DEFAULT_DEVICE}
- SoC: ${DX_SOC:-$DX_DEFAULT_SOC}
- RAM: ${DX_RAM:-$DX_DEFAULT_RAM}
- Kernel base: ${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}

Objetivo:
Performance without unnecessary waste.

Política de IA:
- No usar modelo generativo pesado en background.
- Motor ligero de decisiones con reglas y aprendizaje adaptativo.
- Priorizar estabilidad y consumo RAM controlado.

Capas:
1) Dandelion AI Engine
2) Context Engine
3) Resource Engine
4) Safety Controller
5) Kernel Interface

Motores:
1) X-CPU Engine
2) HyperRAM
3) GPU Intelligence
4) I/O Accelerator
5) Thermal Guardian
6) Touch & Response
7) Learning Engine

Compatibilidad Android objetivo:
- ${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}
- Política: A15/A16 stable, A17 experimental en kernel 4.19
EOF_BLUE
}

write_version_matrix_layout() {
  local dx_dir="$1"
  local version_dir target

  parse_android_targets "${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"

  for target in "${DX_PARSED_TARGETS[@]}"; do
    version_dir="$dx_dir/versions/$target"

    mkdir -p "$version_dir"/{patches,sepolicy,overlays,properties,device,vendor,build,artifacts,logs}

    cat > "$version_dir/build/source_pinning.conf" <<EOF_PIN
android_target=$target
kernel_source_path=${KERNEL_SOURCE_PATH:-pendiente}
expected_device_tree_repo=pendiente
expected_vendor_repo=pendiente
notes=No mezclar vendor/device entre versiones Android.
EOF_PIN

    cat > "$version_dir/build/stability.conf" <<EOF_STABILITY
android_target=$target
stability_tier=$(target_stability_tier "$target")
policy=Aplicar parches comunes + parches específicos de versión.
EOF_STABILITY

    cat > "$version_dir/build/packaging.conf" <<EOF_PACK
android_target=$target
boot_output_name=boot-${target}.img
vendor_boot_output_name=vendor_boot-${target}.img
artifact_label=${target}-linux419
EOF_PACK
  done
}

generate_matrix_plan() {
  local matrix_plan="$1"

  parse_android_targets "${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"

  {
    echo "=== Dandelion X Android Matrix Plan ==="
    echo "Fecha: $(date)"
    echo "Targets: ${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"
    echo ""
    echo "Estrategia por ramas:" 
    echo "- Crear ramas: a15, a16, a17"
    echo "- Mantener kernel base común y separar parches por versión"
    echo ""
    echo "Capas de compatibilidad:"
    echo "- common/patches/{cpu,ram,io,thermal,gpu,touch,learning}"
    echo "- versions/<target>/{patches,sepolicy,overlays,properties}"
    echo ""
    echo "Build matrix:"
    for target in "${DX_PARSED_TARGETS[@]}"; do
      echo "- $target => out/kernel-$target + artifacts boot-$target.img/vendor_boot-$target.img"
    done
    echo ""
    echo "Validación por versión: arranque, radio, WiFi/BT, audio, cámara, sensores, carga"
    echo "Política estabilidad: A15/A16 stable, A17 experimental"
  } > "$matrix_plan"
}

generate_dandelionx_validation_matrix() {
  local matrix_file="$1"
  local target

  parse_android_targets "${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"

  {
    echo "=== Dandelion X Validation Matrix ==="
    echo "Fecha: $(date)"
    echo ""
    for target in "${DX_PARSED_TARGETS[@]}"; do
      echo "[$target]"
      echo "- [ ] Arranque completo"
      echo "- [ ] Radio móvil"
      echo "- [ ] WiFi/Bluetooth"
      echo "- [ ] Audio (speaker/mic)"
      echo "- [ ] Cámara"
      echo "- [ ] Sensores"
      echo "- [ ] Carga USB/batería"
      echo "- [ ] dmesg limpio de errores críticos"
      echo "- [ ] /proc/last_kmsg revisado si hubo reinicio"
      echo ""
    done
  } > "$matrix_file"
}

generate_dandelionx_build_matrix_script() {
  local script_file="$1"

  cat > "$script_file" <<'EOF_MATRIX_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${WORK_DIR:-}"
KERNEL_SOURCE_PATH="${KERNEL_SOURCE_PATH:-}"
KERNEL_DEFCONFIG="${KERNEL_DEFCONFIG:-dandelion_defconfig}"
KERNEL_TOOLCHAIN_PATH="${KERNEL_TOOLCHAIN_PATH:-}"
DX_ANDROID_TARGETS="${DX_ANDROID_TARGETS:-a15,a16,a17}"

if [[ -z "$WORK_DIR" || -z "$KERNEL_SOURCE_PATH" ]]; then
  echo "[ERROR] Define WORK_DIR y KERNEL_SOURCE_PATH antes de ejecutar build-matrix.sh"
  exit 1
fi

if [[ ! -f "$KERNEL_SOURCE_PATH/Makefile" ]]; then
  echo "[ERROR] No se encontró Makefile en KERNEL_SOURCE_PATH: $KERNEL_SOURCE_PATH"
  exit 1
fi

IFS=',' read -r -a targets <<< "$DX_ANDROID_TARGETS"

for raw_target in "${targets[@]}"; do
  target="${raw_target// /}"
  [[ -z "$target" ]] && continue

  out_dir="$WORK_DIR/out/kernel-$target"
  pkg_dir="$WORK_DIR/out/package/$target"
  log_dir="$WORK_DIR/dandelionx/versions/$target/logs"
  mkdir -p "$out_dir" "$pkg_dir" "$log_dir"

  build_log="$log_dir/build-$(date +%Y%m%d-%H%M%S).log"

  echo "[INFO] Building target $target"
  if [[ -n "$KERNEL_TOOLCHAIN_PATH" ]]; then
    PATH="$KERNEL_TOOLCHAIN_PATH/bin:$PATH" make -C "$KERNEL_SOURCE_PATH" O="$out_dir" ARCH=arm64 "$KERNEL_DEFCONFIG" | tee "$build_log"
    PATH="$KERNEL_TOOLCHAIN_PATH/bin:$PATH" make -C "$KERNEL_SOURCE_PATH" O="$out_dir" ARCH=arm64 -j"$(nproc)" | tee -a "$build_log"
  else
    make -C "$KERNEL_SOURCE_PATH" O="$out_dir" ARCH=arm64 "$KERNEL_DEFCONFIG" | tee "$build_log"
    make -C "$KERNEL_SOURCE_PATH" O="$out_dir" ARCH=arm64 -j"$(nproc)" | tee -a "$build_log"
  fi

  image_path="$out_dir/arch/arm64/boot/Image.gz-dtb"
  dtbo_path="$out_dir/arch/arm64/boot/dtbo.img"

  if [[ -f "$image_path" ]]; then
    cp -f "$image_path" "$pkg_dir/Image.gz-dtb-$target"
  fi

  if [[ -f "$dtbo_path" ]]; then
    cp -f "$dtbo_path" "$pkg_dir/dtbo-$target.img"
  fi

  cat > "$pkg_dir/pack-$target.sh" <<EOF_PACK
#!/usr/bin/env bash
set -euo pipefail

# Completa rutas para empaquetar boot/vendor_boot del target $target
KERNEL_IMG="$pkg_dir/Image.gz-dtb-$target"
RAMDISK="<ramdisk_original.cpio.gz>"
DTB="<dtb.img>"
DTBO="$pkg_dir/dtbo-$target.img"

echo "Empaqueta boot-$target.img y vendor_boot-$target.img con parámetros stock del target $target"
EOF_PACK
  chmod +x "$pkg_dir/pack-$target.sh"

done

echo "[OK] Build matrix finalizado para: $DX_ANDROID_TARGETS"
EOF_MATRIX_SCRIPT

  chmod +x "$script_file"
}

init_dandelionx_workspace() {
  local dx_dir config_dir engines_dir logs_dir common_dir matrix_dir

  if [[ -z "${WORK_DIR:-}" ]]; then
    echo "[ERROR] Define WORK_DIR antes de iniciar Dandelion X."
    return 1
  fi

  parse_android_targets "${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}"
  DX_ANDROID_TARGETS="$(IFS=,; echo "${DX_PARSED_TARGETS[*]}")"

  dx_dir="$WORK_DIR/dandelionx"
  config_dir="$dx_dir/config"
  engines_dir="$dx_dir/engines"
  logs_dir="$dx_dir/logs"
  common_dir="$dx_dir/common"
  matrix_dir="$dx_dir/matrix"

  mkdir -p "$config_dir" "$engines_dir" "$logs_dir" "$common_dir" "$matrix_dir"
  mkdir -p "$common_dir/patches"/{cpu,ram,io,thermal,gpu,touch,learning}
  mkdir -p "$common_dir"/{sepolicy,overlays,properties,kernelsu}

  cat > "$config_dir/system_profile.conf" <<EOF_PROFILE
profile_name=${DX_PROFILE_NAME:-$DX_DEFAULT_NAME}
tagline=${DX_TAGLINE:-$DX_DEFAULT_TAGLINE}
device=${DX_DEVICE:-$DX_DEFAULT_DEVICE}
soc=${DX_SOC:-$DX_DEFAULT_SOC}
ram=${DX_RAM:-$DX_DEFAULT_RAM}
kernel=${DX_KERNEL_VERSION:-$DX_DEFAULT_KERNEL}
android_targets=${DX_ANDROID_TARGETS:-$DX_DEFAULT_ANDROID_TARGETS}
EOF_PROFILE

  write_dandelionx_layers "$config_dir/layers.conf"
  write_dandelionx_engines "$engines_dir"
  write_version_matrix_layout "$dx_dir"
  generate_dandelionx_blueprint "$logs_dir/dandelionx_blueprint.txt"
  generate_matrix_plan "$matrix_dir/plan.txt"
  generate_dandelionx_validation_matrix "$matrix_dir/validation-matrix.txt"
  generate_dandelionx_build_matrix_script "$matrix_dir/build-matrix.sh"

  echo "[OK] Dandelion X multiversión inicializado en: $dx_dir"
}
