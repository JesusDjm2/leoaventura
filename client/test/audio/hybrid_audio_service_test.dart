import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/services/bundled_clip_player.dart';
import 'package:leo_parvulos_app/services/speech_synthesizer.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

class _FakeClipPlayer implements ClipAudioPlayer {
  final Set<String> availableClips;
  final List<String> playedClips = [];
  int stopCalls = 0;

  _FakeClipPlayer(this.availableClips);

  @override
  Future<void> ensureInitialized() async {}

  @override
  bool hasClip(String clipId) => availableClips.contains(clipId);

  @override
  Future<bool> playClip(String clipId) async {
    if (!hasClip(clipId)) return false;
    playedClips.add(clipId);
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakeSpeechSynthesizer implements SpeechSynthesizer {
  final List<String> spokenTexts = [];
  int stopCalls = 0;

  @override
  Future<void> speak(
    String text, {
    String language = 'es-ES',
    double rate = 0.88,
  }) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  group('Sprint A Paso 2: Motor Híbrido de Audio Real (Grabación + Voz)', () {
    test('Prioridad 1: reproduce grabación humana cuando el clip existe en el manifiesto', () async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_m', 'fonemas/fonema_s'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      await audio.playClip(
        'fonemas/fonema_m',
        fallbackText: 'Traza la letra M',
      );

      expect(clipPlayer.playedClips, ['fonemas/fonema_m']);
      expect(synth.spokenTexts, isEmpty);
      expect(audio.audioLogs, ['Traza la letra M']);
    });

    test('Prioridad 2: usa síntesis de voz en español cuando el fonema aún no tiene grabación', () async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_m'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      await audio.playClip(
        'fonemas/fonema_l',
        fallbackText: '¡Hola! Traza la letra L con tu dedito.',
      );

      expect(clipPlayer.playedClips, isEmpty);
      expect(synth.spokenTexts, ['¡Hola! Traza la letra L con tu dedito.']);
    });

    testWidgets('Botones de altavoz en LetterTracing y SoundMatchGame disparan el audio real', (tester) async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_s', 'fonemas/fonema_p'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      // 1. LetterTracing con botón de altavoz
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LetterTracing(
              letter: 's',
              audioKey: 'fonemas/fonema_s',
              ttsService: audio,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(clipPlayer.playedClips, ['fonemas/fonema_s']);

      await tester.tap(find.byKey(const Key('tracing_play_sound_btn')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(clipPlayer.playedClips, ['fonemas/fonema_s', 'fonemas/fonema_s']);

      // 2. SoundMatchGame con botón interactivo de fonema
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundMatchGame(
              targetLetter: 'P',
              targetPhoneme: '/p/',
              audioKey: 'fonemas/fonema_p',
              ttsService: audio,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(clipPlayer.playedClips.last, 'fonemas/fonema_p');

      await tester.tap(find.byKey(const Key('sound_match_play_btn')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(clipPlayer.playedClips.where((c) => c == 'fonemas/fonema_p').length, 2);
    });
  });
}
