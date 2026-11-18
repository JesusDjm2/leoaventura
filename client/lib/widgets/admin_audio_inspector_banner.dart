import 'package:flutter/material.dart';
import '../services/parent_settings_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Indicador flotante exclusivo para el Administrador (desactivado por defecto).
///
/// Cuando se activa en Ajustes Parentales ("Indicador Admin de Audio"), muestra
/// en tiempo real si el último sonido reproducido provino de una **voz grabada**
/// (`GRABADO`) o de la **voz sintética temporal** (`SINTÉTICO`), junto al `clip_id`
/// exacto que falta grabar en `/gestion-leo/audio`.
///
/// No bloquea ninguna interacción táctil (`IgnorePointer`).
class AdminAudioInspectorBanner extends StatelessWidget {
  const AdminAudioInspectorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ParentSettingsState.revision,
      builder: (context, _, __) {
        if (!ParentSettingsState.adminAudioInspector) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<AudioPlaybackEvent?>(
          valueListenable: ParvuloTtsService.lastPlayback,
          builder: (context, event, __) {
            final isRecorded = event?.isRecorded ?? false;
            final badgeColor = event == null
                ? AppColors.navy
                : isRecorded
                    ? AppColors.secondary
                    : const Color(0xFFD97706);

            final label = event == null
                ? 'MODO ADMIN AUDIO · Toca cualquier letra o botón'
                : isRecorded
                    ? '🎙️ VOZ GRABADA'
                    : '🤖 VOZ SINTÉTICA (Falta grabar)';

            final detail = event == null
                ? 'Verás aquí si suena voz grabada o sintética.'
                : (event.clipId != null && event.clipId!.isNotEmpty)
                    ? '${event.clipId} · "${event.text}"'
                    : '"${event.text}"';

            return IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Material(
                      key: const Key('admin_audio_inspector_pill'),
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 620),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: badgeColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
