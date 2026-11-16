import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Diálogo de logro al completar una actividad.
///
/// `SuccessDialog` es el contenido (se puede incrustar, p. ej. en la UI
/// Playground); [SuccessDialog.show] lo abre como modal. Usa solo tokens de
/// `app_theme.dart`.
class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.stars = 3,
    this.maxStars = 3,
    this.continueLabel = '¡Seguir!',
    this.onContinue,
  }) : assert(stars >= 0 && stars <= maxStars);

  final String title;
  final String? message;
  final int stars;
  final int maxStars;
  final String continueLabel;
  final VoidCallback? onContinue;

  /// Abre el diálogo como modal. Devuelve cuando el niño pulsa continuar.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    int stars = 3,
    int maxStars = 3,
    String continueLabel = '¡Seguir!',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.navy.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: SuccessDialog(
          title: title,
          message: message,
          stars: stars,
          maxStars: maxStars,
          continueLabel: continueLabel,
          onContinue: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Insignia: círculo verde de marca con check azul marino.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.brandGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 4),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 60,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: '$stars de $maxStars estrellas',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < maxStars; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Star(
                        key: Key('success_star_$i'),
                        earned: i < stars,
                        size: i == 1 ? 56 : 46,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('success_continue'),
              label: continueLabel,
              icon: Icons.arrow_forward_rounded,
              size: PrimaryButtonSize.large,
              expand: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Estrella ganada: naranja de marca con contorno azul marino (como el logo),
/// así el contorno alcanza ≥ 3:1 sobre blanco (WCAG 1.4.11). No ganada: solo
/// contorno en `outline` (4.3:1).
class _Star extends StatelessWidget {
  const _Star({super.key, required this.earned, required this.size});
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!earned) {
      return Icon(
        Icons.star_outline_rounded,
        size: size,
        color: AppColors.outline,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, size: size, color: AppColors.brandOrange),
          Icon(Icons.star_outline_rounded, size: size, color: AppColors.navy),
        ],
      ),
    );
  }
}
