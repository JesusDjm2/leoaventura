import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Tarjeta de lectura fonética para LeoPárvulos (Fase 14).
///
/// Diseñada específicamente para prelectores (3 a 6 años):
/// - Fondo crema suave (`0xFFFFFDF7`) o blanco puro para máximo confort visual.
/// - Texto tipográfico de alta legibilidad usando la fuente **Andika** (SIL),
///   con diseño de caracteres de un solo trazo ('a' y 'g' de un solo piso)
///   que evita confusión en etapas iniciales.
/// - Resaltado opcional de fonemas / grafemas (consonantes o vocales).
/// - Botón opcional de audio/altavoz para reproducción del modelo fonético.
/// - Respuesta táctil adaptada para dedos pequeños.
class ReadingCard extends StatefulWidget {
  /// Texto de la sílaba o palabra (ej. "ma", "sol", "mamá").
  final String text;

  /// Subcadena dentro de [text] que debe resaltarse (ej. "m" o "a").
  final String? highlightedPart;

  /// Color para el fonema/grafema resaltado. Por defecto `AppColors.brandOrange`.
  final Color highlightColor;

  /// Subtítulo o ayuda fonética opcional (ej. "/m/ + /a/").
  final String? subtitle;

  /// Callback al presionar toda la tarjeta.
  final VoidCallback? onTap;

  /// Callback para reproducir el audio del fonema/sílaba.
  final VoidCallback? onAudioTap;

  /// Si el audio se está reproduciendo actualmente (anima el altavoz).
  final bool isAudioPlaying;

  /// Ancho de la tarjeta. Si es nulo, se adapta al contenedor.
  final double? width;

  /// Alto de la tarjeta. Por defecto 160.0.
  final double height;

  /// Color de fondo de la tarjeta. Por defecto crema suave (`0xFFFFFDF7`).
  final Color backgroundColor;

  /// Tamaño de fuente para el texto principal. Por defecto 56.0.
  final double fontSize;

  /// Si la tarjeta se encuentra en estado seleccionado.
  final bool isSelected;

  /// Decoración o imagen ilustrativa superior opcional.
  final Widget? illustration;

  const ReadingCard({
    super.key,
    required this.text,
    this.highlightedPart,
    this.highlightColor = AppColors.brandOrange,
    this.subtitle,
    this.onTap,
    this.onAudioTap,
    this.isAudioPlaying = false,
    this.width,
    this.height = 160.0,
    this.backgroundColor = const Color(0xFFFFFDF7),
    this.fontSize = 56.0,
    this.isSelected = false,
    this.illustration,
  });

  @override
  State<ReadingCard> createState() => _ReadingCardState();
}

class _ReadingCardState extends State<ReadingCard> {
  bool _isHoveredOrPressed = false;

  Widget _buildHighlightedText() {
    final baseStyle = GoogleFonts.andika(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
      letterSpacing: 2.0,
      height: 1.15,
    );

    final highlightStyle = baseStyle.copyWith(
      color: widget.highlightColor,
      fontWeight: FontWeight.w800,
    );

    if (widget.highlightedPart == null ||
        widget.highlightedPart!.isEmpty ||
        !widget.text.contains(widget.highlightedPart!)) {
      return Text(
        widget.text,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    final spans = <TextSpan>[];
    final target = widget.highlightedPart!;
    int start = 0;

    while (start < widget.text.length) {
      final index = widget.text.indexOf(target, start);
      if (index == -1) {
        spans.add(TextSpan(text: widget.text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: widget.text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(text: target, style: highlightStyle));
      start = index + target.length;
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.isSelected
        ? AppColors.brandOrange
        : (widget.onTap != null && _isHoveredOrPressed
            ? AppColors.tertiary
            : AppColors.outlineVariant);

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: 'Tarjeta de lectura: ${widget.text}. ${widget.subtitle ?? ""}',
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isHoveredOrPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isHoveredOrPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isHoveredOrPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: Matrix4.translationValues(
            0,
            _isHoveredOrPressed ? -2.0 : (widget.isSelected ? -4.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: effectiveBorderColor,
              width: widget.isSelected ? 3.0 : 2.0,
            ),
            boxShadow: [
              // Sombra difusa multicapa
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.brandOrange.withValues(alpha: 0.25)
                    : AppColors.navy.withValues(alpha: 0.08),
                blurRadius: widget.isSelected ? 16 : 10,
                offset: Offset(0, widget.isSelected ? 8 : 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Contenido central
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.illustration != null) ...[
                        widget.illustration!,
                        const SizedBox(height: 8),
                      ],
                      _buildHighlightedText(),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: GoogleFonts.andika(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botón de audio fonético en la esquina superior derecha
              if (widget.onAudioTap != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    button: true,
                    label: 'Escuchar pronunciación de ${widget.text}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onAudioTap,
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isAudioPlaying
                                ? AppColors.brandOrange
                                : AppColors.brandCyan.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isAudioPlaying
                                  ? AppColors.brandOrange
                                  : AppColors.brandCyan.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            widget.isAudioPlaying
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            size: 22,
                            color: widget.isAudioPlaying
                                ? AppColors.navy
                                : AppColors.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
