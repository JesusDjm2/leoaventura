import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta de lectura: muestra una palabra (o letra) para que el niño la lea.
///
/// * La palabra usa Andika en negrita (`AppTypography.readingWord`), 72 dp por
///   defecto: legible desde ~60 cm en una tablet (ver
///   `docs/design/design_system.md` §7).
/// * Si se pasan [syllables], se alternan **azul marino** y **naranja AA**
///   para mostrar la división silábica (ambos ≥ 6.4:1 sobre blanco).
/// * La palabra se reduce con `FittedBox` si no cabe: nunca hay overflow.
/// * Usa solo tokens de `app_theme.dart`.
class ReadingCard extends StatelessWidget {
  const ReadingCard({
    super.key,
    required this.word,
    this.syllables,
    this.caption,
    this.illustration,
    this.onListen,
    this.onTap,
    this.selected = false,
    this.wordSize = 72,
  });

  /// Toque sobre la tarjeta (p. ej. elegir la palabra correcta). Se expone en
  /// el mismo nodo semántico que la palabra, así el lector de pantalla anuncia
  /// "mamá, botón, seleccionado".
  final VoidCallback? onTap;

  final String word;

  /// División silábica, p. ej. `['ma', 'má']`. Debe concatenar a [word].
  final List<String>? syllables;

  /// Texto de apoyo bajo la palabra (p. ej. "Toca para escuchar").
  final String? caption;

  /// Ilustración opcional sobre la palabra.
  final Widget? illustration;

  /// Muestra el botón "Escuchar" (≥ 56 dp) si no es null.
  final VoidCallback? onListen;

  /// Borde naranja (AA) grueso: tarjeta activa o elegida.
  final bool selected;

  final double wordSize;

  static const Color syllableColorA = AppColors.navy;
  static const Color syllableColorB = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final base = AppTypography.readingWord(size: wordSize);
    final parts = (syllables?.isEmpty ?? true) ? null : syllables;

    final wordSpan = parts == null
        ? TextSpan(text: word, style: base)
        : TextSpan(
            children: [
              for (var i = 0; i < parts.length; i++)
                TextSpan(
                  text: parts[i],
                  style: base.copyWith(
                    color: i.isEven ? syllableColorA : syllableColorB,
                  ),
                ),
            ],
          );

    return Semantics(
      container: true,
      label: parts == null ? word : '$word, sílabas: ${parts.join(' - ')}',
      button: onTap != null,
      selected: onTap != null ? selected : null,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        // La acción ya está en el Semantics de arriba.
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        child: _card(text, wordSpan),
      ),
    );
  }

  Widget _card(TextTheme text, InlineSpan wordSpan) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          // primary (6.45:1) y no brandOrange (2.3:1): indicador de estado ≥ 3:1.
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: selected ? 5 : 2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null) ...[
            SizedBox(height: wordSize * 1.2, child: illustration),
            const SizedBox(height: 8),
          ],
          ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                wordSpan,
                key: const Key('reading_card_word'),
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (caption != null || onListen != null) const SizedBox(height: 12),
          if (caption != null || onListen != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onListen != null)
                  IconButton.filled(
                    onPressed: onListen,
                    tooltip: 'Escuchar $word',
                    iconSize: 30,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      foregroundColor: AppColors.navy,
                      minimumSize: const Size(56, 56),
                    ),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                if (caption != null && onListen != null)
                  const SizedBox(width: 12),
                if (caption != null)
                  Flexible(
                    child: Text(
                      caption!,
                      style: text.bodyMedium!.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
