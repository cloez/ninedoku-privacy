# Revisión de localización ES — `app_strings.dart` (_es)

## 1. Puntuación general: **7.5 / 10**

Español natural y comprensible en general, con buena terminología de puzzles. Pierde puntos por: inglés sin traducir (badges, tutorial Sudoku, casi todo Binairo), capitalización tipo título estilo inglés, y abreviaturas innecesarias.

## 2. Categorías fuertes
- **Sudoku core (game., difficulty., result., stats.)**: natural, conciso, móvil-friendly.
- **Signos ¿ ¡**: correctamente usados (`¿Rendirse?`, `¡Felicidades!`, `¡Bienvenido!`).
- **Terminología de puzzle**: "celda", "pista", "racha", "dificultad" coherentes.
- **Tuteo (tú)**: consistente en CTAs y mensajes (`Tu progreso`, `Empieza`, `Sigue tu Progreso`).

## 3. P0 — Correcciones inmediatas (máx. 5)

| Clave | Actual | Sugerido |
|---|---|---|
| `badge.firstClear` … `badge.streak30` (15 claves) | Inglés (`First Step`, `Perfectionist`, `3 days streak`…) | Traducir: `Primer Paso`, `Perfeccionista`, `Racha de 3 días`… |
| `tutorial.page1..6.title/desc` + `sudoku.about.*` + `sudoku.rules.*` | Inglés completo (`What is Sudoku?`, `Fill a 9×9 grid…`) | Traducir todo el tutorial al español |
| `binairo.*` (casi todas las cadenas: title, back, pause, result, rules, badges) | Inglés (`Back to Hub`, `Today's Puzzle`, `Give Up`, `Statistics`) | Traducir bloque Binairo completo a ES |
| `home.newGame` / `home.tutorial` / `mode.classic` / etc. | Mayúsculas tipo título (`Nuevo Juego`, `Cómo Jugar`, `Modo de Juego`) | Sentence case ES: `Nuevo juego`, `Cómo jugar`, `Modo de juego` |
| `pause.home` | `Inicio (Auto Guardar)` | `Inicio (guardado automático)` |

## 4. P1 — Mejoras graduales (máx. 10)

1. `home.subtitle`: "Relájate, una celda a la vez" — natural; considerar "Relájate, celda a celda".
2. `difficulty.medium`: `Medio` → `Medio` ok, pero más estándar **`Medio`/`Intermedio`** según UI.
3. `game.numberFirst`: `Núm` → `Número` (cabe) o `N.º`.
4. `stats.avgTime`/`avgMistakes`/`avgHints`: `Tiempo Med.` → `T. medio`, `Errores medios`, `Pistas medias` (evitar "Med." ambiguo).
5. `stats.headerAvgTime`: `Medio` → `Promedio` (más claro como encabezado).
6. `daily.weekday.wed`: `X` (España) ok; en LATAM más común `Mi`. Considerar `Mi` para neutralidad.
7. `settings.autoComplete.desc`: "Auto-rellenar cuando todas las celdas restantes están determinadas" → "Rellenar automáticamente cuando solo queda una solución posible".
8. `settings.vibration.desc`: `Vibrar en entrada y errores` → `Vibrar al introducir números y en errores`.
9. `donation.message`: "Si disfrutas esta app," (frase cortada) → "Si disfrutas la app, considera apoyarnos.".
10. `result.grade.s/a/b/c`: cadenas con concatenación (`'S: 0 errores · 0 pistas · '`) — frágil i18n; idealmente usar placeholders, pero el texto en sí está bien.

## 5. Consistencia de tono
- **Tuteo (tú)** se mantiene en todo el archivo ES traducido. ✅ Mantener.
- **Voz**: amigable y directa. Evitar mezcla con mayúsculas tipo título inglés.
- **Móvil**: longitudes adecuadas salvo `Inicio (Auto Guardar)` y descripciones de ajustes (algo largas pero aceptables).
- **Riesgo principal**: ~40% de cadenas Binairo/badges/tutorial siguen en inglés — rompe inmersión ES gravemente.

## 6. (NO se modificó código)

---

**한국어 요약**: 스페인어 번역은 전반적으로 자연스럽고 튜테오(tú) 일관성과 ¿/¡ 사용이 정확합니다(7.5/10). 그러나 **Binairo 블록 거의 전체, 배지 15개, Sudoku 튜토리얼 전체가 영어로 남아 있어** 최우선 수정 대상입니다. 또한 영어식 Title Case(`Nuevo Juego`)를 스페인어 관례인 sentence case(`Nuevo juego`)로 통일 권장, `Núm`·`Med.` 같은 과도한 축약은 풀어쓰는 것이 모바일 UX에 더 적합합니다.
