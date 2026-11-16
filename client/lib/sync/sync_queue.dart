import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'backoff_policy.dart';
import 'connectivity_monitor.dart';
import 'sync_api_client.dart';
import 'sync_database.dart';

/// Evento de progreso pedagógico generado en el dispositivo.
class ProgressEvent {
  ProgressEvent({
    required this.childId,
    required this.activityId,
    required this.score,
    this.stars,
    this.metadata,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  final int childId;
  final String activityId;
  final int score;
  final int? stars;
  final Map<String, dynamic>? metadata;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

/// Resultado agregado de una ejecución de [SyncQueue.flush].
class SyncFlushResult {
  int sent = 0;
  int requeued = 0;
  int failed = 0;
  bool skippedOffline = false;

  @override
  String toString() => 'SyncFlushResult(sent: $sent, requeued: $requeued, '
      'failed: $failed, offline: $skippedOffline)';
}

typedef TimerFactory = Timer Function(Duration delay, void Function() cb);

/// Cola de sincronización offline-first.
///
/// * [enqueue] persiste siempre primero en SQLite (nunca se pierde un evento).
/// * [flush] envía lotes FIFO a `POST /api/sync/progress` si hay red.
/// * Un fallo transitorio reencola el lote con backoff exponencial y programa
///   un reintento; un fallo permanente (403/422) lo marca como `failed`.
/// * [flush] es *single-flight*: llamadas concurrentes comparten la ejecución
///   en curso y, si llegaron eventos nuevos mientras tanto, se drena otra vez.
class SyncQueue {
  SyncQueue({
    required this.db,
    required this.api,
    required this.connectivity,
    this.backoff = const BackoffPolicy(),
    this.batchSize = 50,
    DateTime Function()? clock,
    TimerFactory? timerFactory,
    this.onError,
  })  : _clock = clock ?? DateTime.now,
        _timerFactory = timerFactory ?? Timer.new;

  final SyncDatabase db;
  final SyncApiClient api;
  final ConnectivityMonitor connectivity;
  final BackoffPolicy backoff;
  final int batchSize;
  final void Function(Object error, StackTrace st)? onError;

  final DateTime Function() _clock;
  final TimerFactory _timerFactory;

  StreamSubscription<bool>? _connSub;
  Timer? _retryTimer;
  Future<SyncFlushResult>? _inFlight;
  bool _rerunRequested = false;
  bool _disposed = false;

  int get _nowMs => _clock().millisecondsSinceEpoch;

  /// Escucha cambios de red: al recuperar conexión se drena la cola.
  void start() {
    _connSub ??= connectivity.onStatusChange.listen((online) {
      if (online) _trigger();
    });
    _trigger();
  }

  /// Guarda el evento localmente y, si hay red, intenta enviarlo.
  Future<int> enqueue(ProgressEvent e, {bool autoFlush = true}) async {
    final id = await db.insertEvent(PendingSyncEventsCompanion.insert(
      childId: e.childId,
      activityId: e.activityId,
      score: e.score,
      stars: Value(e.stars),
      metadata: Value(e.metadata == null ? null : jsonEncode(e.metadata)),
      updatedAt: e.updatedAt.toUtc().toIso8601String(),
      deletedAt: Value(e.deletedAt?.toUtc().toIso8601String()),
      createdAt: _nowMs,
    ));
    if (autoFlush) _trigger();
    return id;
  }

  /// Dispara un flush sin esperar; los errores se reportan a [onError].
  void _trigger() {
    if (_disposed) return;
    flush().catchError((Object e, StackTrace st) {
      onError?.call(e, st);
      return SyncFlushResult();
    });
  }

  Future<SyncFlushResult> flush() {
    final current = _inFlight;
    if (current != null) {
      _rerunRequested = true;
      return current;
    }
    return _inFlight = _run();
  }

  Future<SyncFlushResult> _run() async {
    final result = SyncFlushResult();
    try {
      do {
        _rerunRequested = false;
        if (!await connectivity.isOnline()) {
          result.skippedOffline = true;
          break;
        }
        await _drain(result);
        await _scheduleNextRetry();
        // Sin `await` entre esta comprobación y liberar `_inFlight`, de modo
        // que ninguna llamada a flush() pueda quedar "perdida".
      } while (_rerunRequested && !_disposed);
      return result;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _drain(SyncFlushResult result) async {
    while (!_disposed) {
      final batch = await db.dueEvents(_nowMs, batchSize);
      if (batch.isEmpty) return;
      final ids = [for (final r in batch) r.id];
      try {
        await api.pushProgress([for (final r in batch) _toJson(r)]);
        await db.markSynced(ids, _nowMs);
        result.sent += batch.length;
      } on SyncException catch (e) {
        if (e.isRetryable) {
          final now = _nowMs;
          await db.requeue(
            batch,
            error: e.toString(),
            nextAttemptAtFor: (n) => now + backoff.delayFor(n).inMilliseconds,
          );
          result.requeued += batch.length;
          return; // Servidor/red inestable: no insistir con más lotes ahora.
        }
        await db.markFailed(ids, e.toString());
        result.failed += batch.length;
      }
    }
  }

  Future<void> _scheduleNextRetry() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    final next = await db.nextPendingAttemptAt();
    if (next == null || _disposed) return;
    final delay = Duration(milliseconds: next - _nowMs);
    if (delay <= Duration.zero) return; // Se drenará en la próxima ejecución.
    _retryTimer = _timerFactory(delay, _trigger);
  }

  static Map<String, dynamic> _toJson(PendingSyncEvent r) => {
        'child_id': r.childId,
        'activity_id': r.activityId,
        'score': r.score,
        'stars': r.stars,
        'metadata': r.metadata == null ? null : jsonDecode(r.metadata!),
        'updated_at': r.updatedAt,
        'deleted_at': r.deletedAt,
      };

  Future<void> dispose() async {
    _disposed = true;
    await _connSub?.cancel();
    _retryTimer?.cancel();
    await _inFlight?.catchError((_) => SyncFlushResult());
  }
}
