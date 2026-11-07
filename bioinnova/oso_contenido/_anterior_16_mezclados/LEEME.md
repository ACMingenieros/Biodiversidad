# Contenido del Oso de Anteojos – BioInnova

## Cómo funciona (offline)
1. Cada QR contiene solo un texto corto: `BIOINNOVA:ANI-001`. No contiene URL ni requiere internet.
2. La app lee el QR, verifica que empiece con `BIOINNOVA:` (ignora cualquier otro QR) y busca el `id` en `oso_contenido.json`, que va empaquetado dentro de la app.
3. El oso reproduce el punto:
   - un `saludo` elegido al azar de la lista `saludos` (así no repite siempre lo mismo),
   - los `mensajes` en orden; cada uno trae `animacion` sugerida y `duracion_s` estimada para el globo de texto o la voz,
   - la `pregunta` final opcional (`correcta` es el índice de la opción; mezclar las opciones en la app, porque en el JSON la correcta siempre es la 0).

## Animaciones que el modelo del oso necesita
saludar, explicar, sorprendido, serio_amable, despedirse, celebrar, pensar.

## Validación (importante)
- `fuente: "manual"`: texto basado en el PDF/Word.
- `fuente: "por_validar"`: el PDF solo nombra al animal (dice "(descripción)" / "(características)") o trae datos errados. El texto usa conocimiento general y un biólogo del centro debe revisarlo antes de publicarlo. Cada punto explica el motivo en `nota_validacion`, y en el PDF imprimible la tarjeta dice POR VALIDAR.

## Archivos
- `oso_contenido.json`: todos los textos.
- `qr/svg/`: QR vectoriales, para imprenta y gigantografías.
- `qr/png/`: QR en imagen.
- `QR_imprimibles.pdf`: tarjetas A4, 6 por hoja. Se verificó que los 16 QR del PDF se leen.

Para exteriores: imprimir cada QR de al menos 5 × 5 cm, en vinil mate (el brillo da reflejos que impiden la lectura) y protegido de la lluvia.
