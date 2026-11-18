import 'activity_model.dart';

/// Catálogo offline-first de respaldo de los 20 fonemas del currículo español
/// (espejo determinista de `CurriculumSeeder.php`), enriquecido con:
/// - Fusión silábica (`syllable_builder`) para todas las consonantes.
/// - Lectura guiada de palabras reales (`word_reading`) para los 20 fonemas.
///
/// Garantiza arranque en 0 ms incluso sin conexión al servidor Laravel.
class DefaultCurriculumCatalog {
  static const Set<String> _vowels = {'a', 'e', 'i', 'o', 'u'};

  static const Map<int, String> unitLabels = {
    1: 'Vocales',
    2: 'Consonantes 1',
    3: 'Consonantes 2',
    4: 'Consonantes 3',
  };

  static const List<Map<String, dynamic>> _phonemeSpecs = [
    // Unidad 1: Vocales (5)
    {'unit': 1, 'letter': 'a', 'phoneme': '/a/', 'cue': 'Aaa', 'word': 'Árbol', 'syllables': ['ÁR', 'BOL'], 'slug': 'arbol', 'emoji': '🌳'},
    {'unit': 1, 'letter': 'e', 'phoneme': '/e/', 'cue': 'Eee', 'word': 'Elefante', 'syllables': ['E', 'LE', 'FAN', 'TE'], 'slug': 'elefante', 'emoji': '🐘'},
    {'unit': 1, 'letter': 'i', 'phoneme': '/i/', 'cue': 'Iii', 'word': 'Isla', 'syllables': ['IS', 'LA'], 'slug': 'isla', 'emoji': '🏝️'},
    {'unit': 1, 'letter': 'o', 'phoneme': '/o/', 'cue': 'Ooo', 'word': 'Oso', 'syllables': ['O', 'SO'], 'slug': 'oso', 'emoji': '🐻'},
    {'unit': 1, 'letter': 'u', 'phoneme': '/u/', 'cue': 'Uuu', 'word': 'Uva', 'syllables': ['U', 'VA'], 'slug': 'uva', 'emoji': '🍇'},
    // Unidad 2: Consonantes Iniciales (5)
    {'unit': 2, 'letter': 'm', 'phoneme': '/m/', 'cue': 'Mmm', 'word': 'Mamá', 'syllables': ['MA', 'MÁ'], 'slug': 'mama', 'emoji': '👩'},
    {'unit': 2, 'letter': 'p', 'phoneme': '/p/', 'cue': 'Ppp', 'word': 'Pato', 'syllables': ['PA', 'TO'], 'slug': 'pato', 'emoji': '🦆'},
    {'unit': 2, 'letter': 's', 'phoneme': '/s/', 'cue': 'Sss', 'word': 'Sol', 'syllables': ['SO', 'L'], 'slug': 'sol', 'emoji': '🌞'},
    {'unit': 2, 'letter': 'l', 'phoneme': '/l/', 'cue': 'Lll', 'word': 'Luna', 'syllables': ['LU', 'NA'], 'slug': 'luna', 'emoji': '🌙'},
    {'unit': 2, 'letter': 't', 'phoneme': '/t/', 'cue': 'Ttt', 'word': 'Tortuga', 'syllables': ['TOR', 'TU', 'GA'], 'slug': 'tortuga', 'emoji': '🐢'},
    // Unidad 3: Consonantes Intermedias (5)
    {'unit': 3, 'letter': 'n', 'phoneme': '/n/', 'cue': 'Nnn', 'word': 'Nube', 'syllables': ['NU', 'BE'], 'slug': 'nube', 'emoji': '☁️'},
    {'unit': 3, 'letter': 'd', 'phoneme': '/d/', 'cue': 'Ddd', 'word': 'Dado', 'syllables': ['DA', 'DO'], 'slug': 'dado', 'emoji': '🎲'},
    {'unit': 3, 'letter': 'f', 'phoneme': '/f/', 'cue': 'Fff', 'word': 'Flor', 'syllables': ['FLO', 'R'], 'slug': 'flor', 'emoji': '🌸'},
    {'unit': 3, 'letter': 'r', 'phoneme': '/r/', 'cue': 'Rrr', 'word': 'Ratón', 'syllables': ['RA', 'TÓN'], 'slug': 'raton', 'emoji': '🐭'},
    {'unit': 3, 'letter': 'b', 'phoneme': '/b/', 'cue': 'Bbb', 'word': 'Ballena', 'syllables': ['BA', 'LLE', 'NA'], 'slug': 'ballena', 'emoji': '🐳'},
    // Unidad 4: Consonantes Avanzadas (5)
    {'unit': 4, 'letter': 'c', 'phoneme': '/k/', 'cue': 'Ccc', 'word': 'Casa', 'syllables': ['CA', 'SA'], 'slug': 'casa', 'emoji': '🏠'},
    {'unit': 4, 'letter': 'g', 'phoneme': '/g/', 'cue': 'Ggg', 'word': 'Gato', 'syllables': ['GA', 'TO'], 'slug': 'gato', 'emoji': '🐱'},
    {'unit': 4, 'letter': 'j', 'phoneme': '/x/', 'cue': 'Jjj', 'word': 'Jirafa', 'syllables': ['JI', 'RA', 'FA'], 'slug': 'jirafa', 'emoji': '🦒'},
    {'unit': 4, 'letter': 'v', 'phoneme': '/v/', 'cue': 'Vvv', 'word': 'Vaca', 'syllables': ['VA', 'CA'], 'slug': 'vaca', 'emoji': '🐄'},
    {'unit': 4, 'letter': 'ñ', 'phoneme': '/ɲ/', 'cue': 'Ñññ', 'word': 'Ñandú', 'syllables': ['ÑAN', 'DÚ'], 'slug': 'nandu', 'emoji': '🐦'},
  ];

  static List<CurriculumLevelModel>? _cachedLevels;

  /// Devuelve los 20 niveles fonéticos en orden pedagógico (Vocales -> Consonantes 1-3).
  static List<CurriculumLevelModel> get levels {
    _cachedLevels ??= _buildOfflineLevels();
    return _cachedLevels!;
  }

  /// Obtiene un nivel concreto por letra (ej. `'m'`, `'p'`, `'s'`).
  static CurriculumLevelModel levelForLetter(String letter) {
    final normalized = letter.trim().toLowerCase();
    return levels.firstWhere(
      (l) => l.letter.toLowerCase() == normalized,
      orElse: () => levels.firstWhere(
        (l) => l.letter.toLowerCase() == 'm',
        orElse: () => levels.first,
      ),
    );
  }

  /// Enriquece un nivel recibido del backend añadiendo:
  /// 1. `syllable_builder` (si es consonante y aún no viene incluida).
  /// 2. `word_reading` ("Lee tu primera palabra" por sílabas + comprensión).
  static CurriculumLevelModel augmentLevelWithSyllables(
    CurriculumLevelModel level,
  ) {
    final lower = level.letter.trim().toLowerCase();
    final isConsonant = lower.isNotEmpty && !_vowels.contains(lower);
    final hasSyllables =
        level.activities.any((a) => a.type == ActivityTypes.syllableBuilder);
    final hasWordReading =
        level.activities.any((a) => a.type == ActivityTypes.wordReading);

    if ((!isConsonant || hasSyllables) && hasWordReading) {
      return level;
    }

    final slug = lower == 'ñ' ? 'enie' : lower;
    final upper = lower.toUpperCase();
    final activities = List<ActivityModel>.from(level.activities);

    if (isConsonant && !hasSyllables) {
      activities.add(
        ActivityModel(
          id: level.id * 100 + 3,
          activityCode: 'act_${slug}_syllable_builder',
          type: ActivityTypes.syllableBuilder,
          title: 'Sílabas con $upper',
          instruction: 'Junta la letra $upper con una vocal.',
          audioKey: level.audioKey,
          orderIndex: activities.length + 1,
          payload: {
            'consonant': upper,
            'example_word': level.exampleWord,
            'audio_key': level.audioKey,
            'vowels': const ['A', 'E', 'I', 'O', 'U'],
          },
        ),
      );
    }

    if (!hasWordReading) {
      activities.add(_buildWordReadingActivity(level, slug, activities.length + 1));
    }

    return CurriculumLevelModel(
      id: level.id,
      code: level.code,
      title: level.title,
      phoneme: level.phoneme,
      letter: level.letter,
      exampleWord: level.exampleWord,
      unit: level.unit,
      orderIndex: level.orderIndex,
      audioKey: level.audioKey,
      activities: List<ActivityModel>.unmodifiable(activities),
    );
  }

  static ActivityModel _buildWordReadingActivity(
    CurriculumLevelModel level,
    String slug,
    int orderIndex,
  ) {
    final lower = level.letter.trim().toLowerCase();
    final specIndex = _phonemeSpecs.indexWhere((s) => s['letter'] == lower);
    final spec = specIndex >= 0 ? _phonemeSpecs[specIndex] : _phonemeSpecs[5];
    final total = _phonemeSpecs.length;
    final idx = specIndex >= 0 ? specIndex : 5;
    final d1 = _phonemeSpecs[(idx + 4) % total];
    final d2 = _phonemeSpecs[(idx + 9) % total];

    final targetWord = level.exampleWord.isNotEmpty
        ? level.exampleWord
        : (spec['word'] as String);
    final syllables = (spec['syllables'] as List).cast<String>();
    final imageSlug = spec['slug'] as String;

    // Determinista pero variado para que la respuesta correcta no esté siempre en el índice 0
    final rawOptions = <Map<String, dynamic>>[
      {
        'word': targetWord,
        'image_key': 'palabras/${slug}_$imageSlug',
        'emoji': spec['emoji'],
        'is_correct': true,
      },
      {
        'word': d1['word'],
        'image_key': 'palabras/${d1['letter']}_${d1['slug']}',
        'emoji': d1['emoji'],
        'is_correct': false,
      },
      {
        'word': d2['word'],
        'image_key': 'palabras/${d2['letter']}_${d2['slug']}',
        'emoji': d2['emoji'],
        'is_correct': false,
      },
    ];
    final shift = idx % 3;
    final orderedOptions = [
      rawOptions[shift],
      rawOptions[(shift + 1) % 3],
      rawOptions[(shift + 2) % 3],
    ];

    return ActivityModel(
      id: level.id * 100 + 4,
      activityCode: 'act_${slug}_word_reading',
      type: ActivityTypes.wordReading,
      title: 'Lee la palabra $targetWord',
      instruction: 'Toca cada sílaba para leer $targetWord y elige su dibujo.',
      audioKey: 'palabras/$imageSlug',
      orderIndex: orderIndex,
      payload: {
        'target_word': targetWord,
        'syllables': syllables,
        'highlight_letter': level.letter,
        'audio_key': 'palabras/$imageSlug',
        'options': orderedOptions,
      },
    );
  }

  static List<CurriculumLevelModel> _buildOfflineLevels() {
    final total = _phonemeSpecs.length;
    final built = <CurriculumLevelModel>[];

    for (var i = 0; i < total; i++) {
      final spec = _phonemeSpecs[i];
      final letter = spec['letter'] as String;
      final upper = letter.toUpperCase();
      final slug = letter == 'ñ' ? 'enie' : letter;
      final phoneme = spec['phoneme'] as String;
      final word = spec['word'] as String;
      final cue = spec['cue'] as String;
      final imageSlug = spec['slug'] as String;
      final emoji = spec['emoji'] as String;
      final unit = spec['unit'] as int;
      final audioKey = 'fonemas/fonema_$slug';

      final d1 = _phonemeSpecs[(i + 5) % total];
      final d2 = _phonemeSpecs[(i + 11) % total];

      final tracingActivity = ActivityModel(
        id: (i + 1) * 10 + 1,
        activityCode: 'act_${slug}_tracing',
        type: ActivityTypes.tracing,
        title: 'Traza la letra $upper',
        instruction: '¡Hola! Traza la letra $upper con tu dedito.',
        audioKey: audioKey,
        orderIndex: 1,
        payload: {
          'letter': letter,
          'phoneme': phoneme,
          'example_word': word,
          'audio_key': audioKey,
          'instruction_audio': 'instrucciones/instruccion_traza_letra_$slug',
          'success_text':
              '¡Excelente! Has trazado la letra $upper. ¡$cue como en $word!',
        },
      );

      final soundMatchActivity = ActivityModel(
        id: (i + 1) * 10 + 2,
        activityCode: 'act_${slug}_sound_match',
        type: ActivityTypes.soundMatch,
        title: 'Encuentra el sonido $phoneme',
        instruction: 'Toca el dibujo que empieza con $phoneme.',
        audioKey: audioKey,
        orderIndex: 2,
        payload: {
          'target_letter': upper,
          'target_phoneme': phoneme,
          'audio_key': audioKey,
          'options': [
            {
              'name': word,
              'image_key': 'palabras/${slug}_$imageSlug',
              'emoji': emoji,
              'is_correct': true,
              'feedback_text': '¡$word! Empieza con $phoneme.',
              'audio_key': 'palabras/$imageSlug',
            },
            {
              'name': d1['word'],
              'image_key': 'palabras/${d1['letter']}_${d1['slug']}',
              'emoji': d1['emoji'],
              'is_correct': false,
              'feedback_text': '${d1['word']} empieza con ${d1['phoneme']}.',
              'audio_key': 'palabras/${d1['slug']}',
            },
            {
              'name': d2['word'],
              'image_key': 'palabras/${d2['letter']}_${d2['slug']}',
              'emoji': d2['emoji'],
              'is_correct': false,
              'feedback_text': '${d2['word']} empieza con ${d2['phoneme']}.',
              'audio_key': 'palabras/${d2['slug']}',
            },
          ],
        },
      );

      final rawLevel = CurriculumLevelModel(
        id: i + 1,
        code: 'phoneme_$slug',
        title: 'Fonema $phoneme - $word',
        phoneme: phoneme,
        letter: letter,
        exampleWord: word,
        unit: unit,
        orderIndex: i + 1,
        audioKey: audioKey,
        activities: [tracingActivity, soundMatchActivity],
      );

      built.add(augmentLevelWithSyllables(rawLevel));
    }

    return List<CurriculumLevelModel>.unmodifiable(built);
  }
}
