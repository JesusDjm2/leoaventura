import 'package:drift/drift.dart';

part 'sync_database.g.dart';

/// Estados posibles de un evento en la cola local.
abstract final class SyncStatus {
  /// Pendiente de envío (o reencolado tras un fallo transitorio).
  static const pending = 'pending';

  /// Confirmado por el servidor (HTTP 200).
  static const synced = 'synced';

  /// Rechazado de forma permanente (403/422): no se reintenta.
  static const failed = 'failed';
}

/// Tabla local `pending_sync_events`: cola persistente de eventos de progreso
/// generados offline. Ver `SYNC_CLIENT.md`.
@DataClassName('PendingSyncEvent')
class PendingSyncEvents extends Table {
  @override
  String get tableName => 'pending_sync_events';

  IntColumn get id => integer().autoIncrement()();

  // --- Payload (contrato de POST /api/sync/progress) ---
  IntColumn get childId => integer().named('child_id')();
  TextColumn get activityId => text().named('activity_id')();
  IntColumn get score => integer()();
  IntColumn get stars => integer().nullable()();

  /// JSON serializado (objeto) o null.
  TextColumn get metadata => text().nullable()();

  /// ISO 8601 UTC — clave de resolución LWW en el servidor.
  TextColumn get updatedAt => text().named('updated_at')();

  /// ISO 8601 UTC o null — soft delete.
  TextColumn get deletedAt => text().named('deleted_at').nullable()();

  // --- Control de la cola ---
  TextColumn get status =>
      text().withDefault(const Constant(SyncStatus.pending))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Epoch ms: el evento no se envía antes de este instante (backoff).
  IntColumn get nextAttemptAt =>
      integer().named('next_attempt_at').withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();

  /// Epoch ms.
  IntColumn get createdAt => integer().named('created_at')();

  /// Epoch ms o null.
  IntColumn get syncedAt => integer().named('synced_at').nullable()();
}

@DriftDatabase(tables: [PendingSyncEvents])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_pending_sync_due '
            'ON pending_sync_events (status, next_attempt_at)',
          );
        },
      );

  Future<int> insertEvent(PendingSyncEventsCompanion row) =>
      into(pendingSyncEvents).insert(row);

  /// Eventos pendientes cuyo backoff ya venció, en orden FIFO.
  Future<List<PendingSyncEvent>> dueEvents(int nowMs, int limit) {
    return (select(pendingSyncEvents)
          ..where((t) =>
              t.status.equals(SyncStatus.pending) &
              t.nextAttemptAt.isSmallerOrEqualValue(nowMs))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
  }

  /// Instante (epoch ms) del próximo evento pendiente, o null si no hay.
  Future<int?> nextPendingAttemptAt() async {
    final minExpr = pendingSyncEvents.nextAttemptAt.min();
    final row = await (selectOnly(pendingSyncEvents)
          ..addColumns([minExpr])
          ..where(pendingSyncEvents.status.equals(SyncStatus.pending)))
        .getSingle();
    return row.read(minExpr);
  }

  Future<void> markSynced(List<int> ids, int nowMs) {
    return (update(pendingSyncEvents)..where((t) => t.id.isIn(ids))).write(
      PendingSyncEventsCompanion(
        status: const Value(SyncStatus.synced),
        syncedAt: Value(nowMs),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(List<int> ids, String error) {
    return (update(pendingSyncEvents)..where((t) => t.id.isIn(ids))).write(
      PendingSyncEventsCompanion(
        status: const Value(SyncStatus.failed),
        lastError: Value(error),
      ),
    );
  }

  /// Reencola un lote tras un fallo transitorio, fijando su próximo intento.
  Future<void> requeue(
    List<PendingSyncEvent> rows, {
    required int Function(int attempts) nextAttemptAtFor,
    required String error,
  }) {
    return transaction(() async {
      for (final r in rows) {
        final attempts = r.attempts + 1;
        await (update(pendingSyncEvents)..where((t) => t.id.equals(r.id)))
            .write(PendingSyncEventsCompanion(
          status: const Value(SyncStatus.pending),
          attempts: Value(attempts),
          nextAttemptAt: Value(nextAttemptAtFor(attempts)),
          lastError: Value(error),
        ));
      }
    });
  }

  Future<List<PendingSyncEvent>> eventsByStatus(String status) =>
      (select(pendingSyncEvents)
            ..where((t) => t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<List<PendingSyncEvent>> allEvents() =>
      (select(pendingSyncEvents)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Limpieza: borra eventos sincronizados más antiguos que [olderThanMs].
  Future<int> purgeSynced(int olderThanMs) =>
      (delete(pendingSyncEvents)
            ..where((t) =>
                t.status.equals(SyncStatus.synced) &
                t.syncedAt.isSmallerThanValue(olderThanMs)))
          .go();
}
