# Android ROM Porter

Asistente en Bash para organizar flujos de porting ROM y compilación de kernel para **Redmi 9A (dandelion)**.

## Uso rápido

```bash
bash /home/runner/work/android-rom-porter/android-rom-porter/porter.sh menu
```

## Comandos

- `bash porter.sh menu` → menú interactivo completo.
- `bash porter.sh init-build` → flujo inicial ROM (workspace + rutas AOSP/STOCK + plan).
- `bash porter.sh kernel-build` → flujo completo kernel para Redmi 9A.
- `bash porter.sh dandelionx-init` → inicializa perfil y estructura **DANDELION X EXTREME**.
- `bash porter.sh dandelionx-build-matrix` → compila matriz por versión Android (A15/A16/A17).
- `bash porter.sh show-config` → muestra configuración actual.

## DANDELION X EXTREME

**Adaptive Performance Intelligence**  
REDMI 9A · HELIO G25 · 2 GB RAM · LINUX 4.19.325

Arquitectura implementada en el workspace con 5 capas:

1. Dandelion AI Engine
2. Context Engine
3. Resource Engine
4. Safety Controller
5. Kernel Interface

Motores incluidos:

1. X-CPU Engine
2. HyperRAM
3. GPU Intelligence
4. I/O Accelerator
5. Thermal Guardian
6. Touch & Response
7. Learning Engine

La IA se define como un motor ligero de decisiones (reglas + aprendizaje local), evitando un modelo generativo pesado residente en RAM.

### Compatibilidad Android 15–17 (estrategia por versiones)

- Targets soportados: `a15`, `a16`, `a17`.
- Estructura por versión con separación de:
  - parches comunes (`common/`)
  - parches específicos por versión (`versions/<target>/`)
  - `sepolicy`, `overlays`, `properties` por target
- Política de estabilidad:
  - `a15` y `a16`: **stable**
  - `a17`: **experimental** (kernel 4.19)
- Build matrix con artefactos etiquetados por versión para evitar flasheos cruzados.

## Flujo kernel implementado

El flujo kernel cubre:

1. Confirmar base del dispositivo (`dandelion`, Android/MIUI, tipo de source).
2. Verificar dependencias Linux para compilación.
3. Preparar source en rama limpia local (si es repo git).
4. Ejecutar `defconfig` objetivo.
5. Compilar kernel y módulos.
6. Copiar artefactos y generar plantilla para empaquetado `boot.img/vendor_boot.img`.
7. Generar checklist de flasheo y validación funcional.
8. Generar reporte de build para depuración iterativa.

## Archivos generados en workspace

- `workspace/logs/build_plan.txt`
- `workspace/logs/kernel_build_report.txt`
- `workspace/logs/flash_test_checklist.txt`
- `workspace/out/package/pack_commands.sh`
- `workspace/dandelionx/config/system_profile.conf`
- `workspace/dandelionx/config/layers.conf`
- `workspace/dandelionx/common/`
- `workspace/dandelionx/engines/*.conf`
- `workspace/dandelionx/logs/dandelionx_blueprint.txt`
- `workspace/dandelionx/versions/a15/`
- `workspace/dandelionx/versions/a16/`
- `workspace/dandelionx/versions/a17/`
- `workspace/dandelionx/matrix/plan.txt`
- `workspace/dandelionx/matrix/validation-matrix.txt`
- `workspace/dandelionx/matrix/build-matrix.sh`

## Notas

- El script no descarga fuentes automáticamente: espera rutas locales ya preparadas.
- Para empaquetado final (`boot.img`/`vendor_boot.img`) debes reutilizar parámetros de imágenes stock del dispositivo.
