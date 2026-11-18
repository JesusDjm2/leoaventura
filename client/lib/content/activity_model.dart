import 'dart:ui' show Offset;

/// Identificadores estándar de tipos de actividades soportados por el motor.
/// El motor acepta cualquier tipo registrado dinámicamente en `ActivityRegistry`.
abstract final class ActivityTypes {
  static const String tracing = 'tracing';
  static const String soundMatch = 'sound_match';
  static const String syllableBuilder = 'syllable_builder';
  static const String wordReading = 'word_reading';
}

/// Payload tipado para actividades de trazado táctil (`type == 'tracing'`).
class TracingPayload {
  final String letter;
  final String phoneme;
  final String exampleWord;
  final String audioKey;
  final String? instructionAudio;
  final String? successText;
  final List<Offset> checkpoints;

  const TracingPayload({
    required this.letter,
    required this.phoneme,
    required this.exampleWord,
    required this.audioKey,
    this.instructionAudio,
    this.successText,
    this.checkpoints = const [],
  });

  factory TracingPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackAudioKey = '',
  }) {
    final rawCheckpoints = json['checkpoints'];
    final parsedCheckpoints = <Offset>[];

    if (rawCheckpoints is List) {
      for (final point in rawCheckpoints) {
        if (point is Map) {
          final x = (point['x'] as num?)?.toDouble();
          final y = (point['y'] as num?)?.toDouble();
          if (x != null && y != null) {
            parsedCheckpoints.add(Offset(x, y));
          }
        } else if (point is List && point.length >= 2) {
          final x = (point[0] as num?)?.toDouble();
          final y = (point[1] as num?)?.toDouble();
          if (x != null && y != null) {
            parsedCheckpoints.add(Offset(x, y));
          }
        }
      }
    }

    final letter = (json['letter'] as String? ?? '').trim();
    if (letter.isEmpty) {
      throw const FormatException('TracingPayload requiere el campo no vacío "letter".');
    }

    return TracingPayload(
      letter: letter,
      phoneme: (json['phoneme'] as String?) ?? '/${letter.toLowerCase()}/',
      exampleWord: (json['example_word'] as String?) ?? '',
      audioKey: (json['audio_key'] as String?) ?? fallbackAudioKey,
      instructionAudio: json['instruction_audio'] as String?,
      successText: json['success_text'] as String?,
      checkpoints: List<Offset>.unmodifiable(parsedCheckpoints),
    );
  }

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'phoneme': phoneme,
        'example_word': exampleWord,
        'audio_key': audioKey,
        if (instructionAudio != null) 'instruction_audio': instructionAudio,
        if (successText != null) 'success_text': successText,
        'checkpoints': checkpoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };
}

/// Opción individual para actividades de emparejamiento de fonema con imagen.
class SoundMatchOption {
  final String name;
  final String imageKey;
  final String emoji;
  final bool isCorrect;
  final String feedbackText;
  final String audioKey;

  const SoundMatchOption({
    required this.name,
    required this.imageKey,
    required this.emoji,
    required this.isCorrect,
    required this.feedbackText,
    required this.audioKey,
  });

  factory SoundMatchOption.fromJson(Map<String, dynamic> json) {
    return SoundMatchOption(
      name: (json['name'] as String?) ?? '',
      imageKey: (json['image_key'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '⭐',
      isCorrect: (json['is_correct'] as bool?) ?? false,
      feedbackText: (json['feedback_text'] as String?) ?? '',
      audioKey: (json['audio_key'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'image_key': imageKey,
        'emoji': emoji,
        'is_correct': isCorrect,
        'feedback_text': feedbackText,
        'audio_key': audioKey,
      };
}

/// Payload tipado para actividades de emparejamiento fonema-imagen (`type == 'sound_match'`).
class SoundMatchPayload {
  final String targetLetter;
  final String targetPhoneme;
  final String audioKey;
  final List<SoundMatchOption> options;

  const SoundMatchPayload({
    required this.targetLetter,
    required this.targetPhoneme,
    required this.audioKey,
    required this.options,
  });

  factory SoundMatchPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackAudioKey = '',
  }) {
    final rawOptions = (json['options'] as List?) ?? const [];
    final options = rawOptions
        .whereType<Map>()
        .map((m) => SoundMatchOption.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);

    return SoundMatchPayload(
      targetLetter: (json['target_letter'] as String?) ?? '',
      targetPhoneme: (json['target_phoneme'] as String?) ?? '',
      audioKey: (json['audio_key'] as String?) ?? fallbackAudioKey,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        'target_letter': targetLetter,
        'target_phoneme': targetPhoneme,
        'audio_key': audioKey,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

/// Payload tipado para actividades de construcción silábica (`type == 'syllable_builder'`).
class SyllableBuilderPayload {
  final String consonant;
  final String exampleWord;
  final String audioKey;
  final List<String> vowels;

  const SyllableBuilderPayload({
    required this.consonant,
    this.exampleWord = '',
    this.audioKey = '',
    this.vowels = const ['A', 'E', 'I', 'O', 'U'],
  });

  factory SyllableBuilderPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackAudioKey = '',
  }) {
    final rawConsonant =
        ((json['consonant'] as String?) ?? (json['letter'] as String?) ?? 'M')
            .trim()
            .toUpperCase();
    final rawVowels = (json['vowels'] as List?)
        ?.map((v) => v.toString().toUpperCase())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    return SyllableBuilderPayload(
      consonant: rawConsonant.isEmpty ? 'M' : rawConsonant,
      exampleWord: (json['example_word'] as String?) ?? '',
      audioKey: (json['audio_key'] as String?) ?? fallbackAudioKey,
      vowels: (rawVowels != null && rawVowels.isNotEmpty)
          ? rawVowels
          : const ['A', 'E', 'I', 'O', 'U'],
    );
  }

  Map<String, dynamic> toJson() => {
        'consonant': consonant,
        'example_word': exampleWord,
        'audio_key': audioKey,
        'vowels': vowels,
      };
}

/// Opción ilustrada para comprensión lectora en [WordReadingPayload].
class WordReadingOption {
  final String word;
  final String imageKey;
  final String emoji;
  final bool isCorrect;

  const WordReadingOption({
    required this.word,
    required this.imageKey,
    required this.emoji,
    required this.isCorrect,
  });

  factory WordReadingOption.fromJson(Map<String, dynamic> json) {
    return WordReadingOption(
      word: (json['word'] as String?) ?? (json['name'] as String?) ?? '',
      imageKey: (json['image_key'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '⭐',
      isCorrect: (json['is_correct'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'image_key': imageKey,
        'emoji': emoji,
        'is_correct': isCorrect,
      };
}

/// Payload tipado para el 4.º minijuego: Lectura guiada de palabras por sílabas
/// (`type == 'word_reading'`).
class WordReadingPayload {
  final String targetWord;
  final List<String> syllables;
  final String highlightLetter;
  final String audioKey;
  final List<WordReadingOption> options;

  const WordReadingPayload({
    required this.targetWord,
    required this.syllables,
    required this.highlightLetter,
    this.audioKey = '',
    required this.options,
  });

  factory WordReadingPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackAudioKey = '',
  }) {
    final targetWord = ((json['target_word'] as String?) ?? '').trim();
    final rawSyllables = (json['syllables'] as List?)
        ?.map((s) => s.toString().trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final rawOptions = (json['options'] as List?) ?? const [];
    final options = rawOptions
        .whereType<Map>()
        .map((m) => WordReadingOption.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);

    return WordReadingPayload(
      targetWord: targetWord.isEmpty ? 'MAMÁ' : targetWord,
      syllables: (rawSyllables != null && rawSyllables.isNotEmpty)
          ? rawSyllables
          : [targetWord.isEmpty ? 'MA' : targetWord.toUpperCase()],
      highlightLetter: ((json['highlight_letter'] as String?) ?? '').trim(),
      audioKey: (json['audio_key'] as String?) ?? fallbackAudioKey,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        'target_word': targetWord,
        'syllables': syllables,
        'highlight_letter': highlightLetter,
        'audio_key': audioKey,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

/// Modelo unificado de actividad dinámica servida por el backend.
///
/// Soporta de serie los tipos [ActivityTypes.tracing] y [ActivityTypes.soundMatch],
/// y conserva [payload] abierto (`Map<String, dynamic>`) para permitir nuevos tipos
/// de minijuegos sin modificar el modelo base ni el núcleo de la aplicación.
class ActivityModel {
  final int id;
  final String activityCode;
  final String type;
  final String title;
  final String instruction;
  final String audioKey;
  final int orderIndex;
  final Map<String, dynamic> payload;

  const ActivityModel({
    required this.id,
    required this.activityCode,
    required this.type,
    required this.title,
    required this.instruction,
    required this.audioKey,
    required this.orderIndex,
    required this.payload,
  });

  bool get isTracing => type == ActivityTypes.tracing;
  bool get isSoundMatch => type == ActivityTypes.soundMatch;
  bool get isSyllableBuilder => type == ActivityTypes.syllableBuilder;
  bool get isWordReading => type == ActivityTypes.wordReading;

  TracingPayload get tracingPayload =>
      TracingPayload.fromJson(payload, fallbackAudioKey: audioKey);

  SoundMatchPayload get soundMatchPayload =>
      SoundMatchPayload.fromJson(payload, fallbackAudioKey: audioKey);

  SyllableBuilderPayload get syllableBuilderPayload =>
      SyllableBuilderPayload.fromJson(payload, fallbackAudioKey: audioKey);

  WordReadingPayload get wordReadingPayload =>
      WordReadingPayload.fromJson(payload, fallbackAudioKey: audioKey);

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? '').trim();
    if (type.isEmpty) {
      throw const FormatException('ActivityModel requiere el campo "type".');
    }

    final rawPayload = json['payload'];
    final payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : <String, dynamic>{};

    return ActivityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      activityCode: (json['activity_code'] as String?) ?? 'act_$type',
      type: type,
      title: (json['title'] as String?) ?? '',
      instruction: (json['instruction'] as String?) ?? '',
      audioKey: (json['audio_key'] as String?) ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.unmodifiable(payload),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'activity_code': activityCode,
        'type': type,
        'title': title,
        'instruction': instruction,
        'audio_key': audioKey,
        'order_index': orderIndex,
        'payload': payload,
      };
}

/// Modelo de nivel fonético del currículo (1 nivel = 1 fonema con sus actividades).
class CurriculumLevelModel {
  final int id;
  final String code;
  final String title;
  final String phoneme;
  final String letter;
  final String exampleWord;
  final int unit;
  final int orderIndex;
  final String audioKey;
  final List<ActivityModel> activities;

  const CurriculumLevelModel({
    required this.id,
    required this.code,
    required this.title,
    required this.phoneme,
    required this.letter,
    required this.exampleWord,
    required this.unit,
    required this.orderIndex,
    required this.audioKey,
    required this.activities,
  });

  factory CurriculumLevelModel.fromJson(Map<String, dynamic> json) {
    final rawActivities = (json['activities'] as List?) ?? const [];
    final activities = rawActivities
        .whereType<Map>()
        .map((a) => ActivityModel.fromJson(Map<String, dynamic>.from(a)))
        .toList(growable: false);

    return CurriculumLevelModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      phoneme: (json['phoneme'] as String?) ?? '',
      letter: (json['letter'] as String?) ?? '',
      exampleWord: (json['example_word'] as String?) ?? '',
      unit: (json['unit'] as num?)?.toInt() ?? 1,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      audioKey: (json['audio_key'] as String?) ?? '',
      activities: activities,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'phoneme': phoneme,
        'letter': letter,
        'example_word': exampleWord,
        'unit': unit,
        'order_index': orderIndex,
        'audio_key': audioKey,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

/// Respuesta completa del endpoint `GET /api/curriculum/levels`.
class CurriculumResponse {
  final String version;
  final int totalPhonemes;
  final List<CurriculumLevelModel> levels;

  const CurriculumResponse({
    required this.version,
    required this.totalPhonemes,
    required this.levels,
  });

  factory CurriculumResponse.fromJson(Map<String, dynamic> json) {
    final rawLevels = (json['levels'] as List?) ?? const [];
    final levels = rawLevels
        .whereType<Map>()
        .map((l) => CurriculumLevelModel.fromJson(Map<String, dynamic>.from(l)))
        .toList(growable: false);

    return CurriculumResponse(
      version: (json['version'] as String?) ?? '1.0',
      totalPhonemes: (json['total_phonemes'] as num?)?.toInt() ?? levels.length,
      levels: levels,
    );
  }
}
