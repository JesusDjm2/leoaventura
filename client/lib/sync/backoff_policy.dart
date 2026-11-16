import 'dart:math';

/// Backoff exponencial con tope y jitter proporcional.
///
/// delay(n) = min(maxDelay, baseDelay * multiplier^(n-1)) * (1 ± jitter)
/// donde `n` es el número de intentos fallidos acumulados (n >= 1).
class BackoffPolicy {
  const BackoffPolicy({
    this.baseDelay = const Duration(seconds: 2),
    this.multiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
    this.jitter = 0.2,
    this.random,
  }) : assert(jitter >= 0 && jitter < 1);

  final Duration baseDelay;
  final double multiplier;
  final Duration maxDelay;

  /// Fracción de variación aleatoria (0.2 = ±20 %). 0 = determinista.
  final double jitter;
  final Random? random;

  Duration delayFor(int attempts) {
    final n = attempts < 1 ? 1 : attempts;
    final raw = baseDelay.inMilliseconds * pow(multiplier, n - 1);
    final capped = min(raw.toDouble(), maxDelay.inMilliseconds.toDouble());
    if (jitter == 0) return Duration(milliseconds: capped.round());
    final r = (random ?? Random()).nextDouble() * 2 - 1; // [-1, 1)
    return Duration(milliseconds: (capped * (1 + jitter * r)).round());
  }
}
