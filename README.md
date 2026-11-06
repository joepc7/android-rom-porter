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
- `bash porter.sh show-config` → muestra configuración actual.

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

## Notas

- El script no descarga fuentes automáticamente: espera rutas locales ya preparadas.
- Para empaquetado final (`boot.img`/`vendor_boot.img`) debes reutilizar parámetros de imágenes stock del dispositivo.
