/// Progreso agregado de un niño en un fonema.
class PhonemeProgress {
  const PhonemeProgress({
    required this.phoneme,
    required this.mastery,
    required this.sessions,
  }) : assert(mastery >= 0 && mastery <= 100);

  /// Grafema mostrado (p. ej. "A", "M").
  final String phoneme;

  /// Dominio 0–100 (promedio de `score` de sus actividades).
  final int mastery;

  /// Número de sesiones de práctica registradas.
  final int sessions;

  MasteryLevel get level => MasteryLevel.of(mastery);
}

enum MasteryLevel {
  initial('Inicial'),
  inProgress('En progreso'),
  mastered('Dominado');

  const MasteryLevel(this.label);
  final String label;

  static MasteryLevel of(int mastery) => mastery >= 80
      ? MasteryLevel.mastered
      : mastery >= 50
          ? MasteryLevel.inProgress
          : MasteryLevel.initial;
}

/// Reporte que ve el padre/docente para un perfil infantil.
class ParentReport {
  const ParentReport({
    required this.childName,
    required this.periodLabel,
    required this.totalPractice,
    required this.phonemes,
    required this.generatedAt,
  });

  final String childName;
  final String periodLabel;
  final Duration totalPractice;
  final List<PhonemeProgress> phonemes;
  final DateTime generatedAt;

  int get totalSessions => phonemes.fold(0, (a, p) => a + p.sessions);
  int get masteredCount =>
      phonemes.where((p) => p.level == MasteryLevel.mastered).length;

  /// Datos de demostración hasta conectar con el backend.
  static ParentReport mock({DateTime? now}) => ParentReport(
        childName: 'Sofía',
        periodLabel: 'Últimos 30 días',
        totalPractice: const Duration(hours: 4, minutes: 35),
        generatedAt: now ?? DateTime(2026, 11, 15, 18, 30),
        phonemes: const [
          PhonemeProgress(phoneme: 'A', mastery: 95, sessions: 6),
          PhonemeProgress(phoneme: 'E', mastery: 88, sessions: 5),
          PhonemeProgress(phoneme: 'I', mastery: 82, sessions: 4),
          PhonemeProgress(phoneme: 'O', mastery: 74, sessions: 4),
          PhonemeProgress(phoneme: 'U', mastery: 61, sessions: 3),
          PhonemeProgress(phoneme: 'M', mastery: 90, sessions: 7),
          PhonemeProgress(phoneme: 'P', mastery: 55, sessions: 3),
          PhonemeProgress(phoneme: 'L', mastery: 38, sessions: 2),
          PhonemeProgress(phoneme: 'S', mastery: 22, sessions: 1),
        ],
      );
}

/// "4 h 35 min", "45 min", "0 min".
String formatPracticeDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}
