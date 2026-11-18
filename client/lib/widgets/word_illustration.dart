import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta ilustrada coherente con el Design System de Leoaventura.
///
/// Soporta carga automática de ilustraciones personalizadas (`assets/words/<slug>.png`)
/// cuando estén disponibles y ofrece un medallón ilustrado cálido y uniforme como
/// presentación base para todos los minijuegos (`SoundMatchGame` y `WordReadingGame`).
class WordIllustration extends StatelessWidget {
  final String imageKey;
  final String emoji;
  final String label;
  final double size;
  final bool highlighted;

  const WordIllustration({
    super.key,
    required this.imageKey,
    required this.emoji,
    required this.label,
    this.size = 64,
    this.highlighted = false,
  });

  static const List<Color> _pastelTints = [
    Color(0xFFFFF3E0), // Naranja cálido suave
    Color(0xFFE8F5E9), // Verde hoja suave
    Color(0xFFE1F5FE), // Celeste cielo suave
    Color(0xFFF3E5F5), // Lavanda suave
    Color(0xFFFFFDE7), // Amarillo sol suave
  ];

  static const List<Color> _ringColors = [
    AppColors.brandOrange,
    AppColors.brandGreen,
    AppColors.brandCyan,
    Color(0xFFB39DDB),
    Color(0xFFFFCA28),
  ];

  int get _paletteIndex {
    final seed = (imageKey.isNotEmpty ? imageKey : label).codeUnits.fold<int>(
          0,
          (acc, c) => acc + c,
        );
    return seed % _pastelTints.length;
  }

  String? get _slug {
    if (imageKey.isEmpty) return null;
    final parts = imageKey.split('/');
    final raw = parts.last.trim();
    return raw.isEmpty ? null : raw;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = highlighted
        ? AppColors.brandGreen.withValues(alpha: 0.35)
        : _pastelTints[_paletteIndex];
    final ringColor =
        highlighted ? AppColors.secondary : _ringColors[_paletteIndex];
    final slug = _slug;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: highlighted ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: slug != null
            ? Image.asset(
                'assets/words/$slug.png',
                width: size * 0.72,
                height: size * 0.72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  emoji,
                  style: TextStyle(fontSize: size * 0.56, height: 1.05),
                ),
              )
            : Text(
                emoji,
                style: TextStyle(fontSize: size * 0.56, height: 1.05),
              ),
      ),
    );
  }
}
