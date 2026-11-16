// Tests de integración de la cola offline-first:
// SQLite real (Drift en memoria) + servidor HTTP real en localhost.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leo_parvulos_app/sync/backoff_policy.dart';
import 'package:leo_parvulos_app/sync/sync_api_client.dart';
import 'package:leo_parvulos_app/sync/sync_database.dart';
import 'package:leo_parvulos_app/sync/sync_queue.dart';

import 'sync_test_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SyncDatabase db;
  late MockSyncServer server;
  late FakeConnectivity net;
  late FakeClock clock;
  late http.Client httpClient;
  late List<FakeTimer> timers;
  late List<Object> queueErrors;
  late SyncQueue queue;

  SyncQueue buildQueue({BackoffPolicy? backoff, int batchSize = 50}) {
    return SyncQueue(
      db: db,
      api: SyncApiClient(
        baseUrl: server.baseUrl,
        httpClient: httpClient,
        tokenProvider: () async => 'test-token',
      ),
      connectivity: net,
      backoff: backoff ?? const BackoffPolicy(jitter: 0),
      batchSize: batchSize,
      clock: clock.call,
      timerFactory: (d, cb) {
        final t = FakeTimer(d, cb);
        timers.add(t);
        return t;
      },
      onError: (e, _) => queueErrors.add(e),
    );
  }

  ProgressEvent event(String activity, {int score = 90}) => ProgressEvent(
        childId: 1,
        activityId: activity,
        score: score,
        stars: 3,
        metadata: {'intentos': 1},
        updatedAt: clock.now,
      );

  setUp(() async {
    db = SyncDatabase(NativeDatabase.memory());
    server = await MockSyncServer.start();
    net = FakeConnectivity();
    clock = FakeClock(DateTime.utc(2026, 11, 15, 12));
    httpClient = http.Client();
    timers = [];
    queueErrors = [];
  });

  tearDown(() async {
    await queue.dispose();
    httpClient.close();
    await server.close();
    await net.close();
    await db.close();
    expect(queueErrors, isEmpty, reason: 'errores no controlados en la cola');
  });

  test(
      'pérdida de red: 3 eventos guardados offline llegan al servidor '
      'al restaurar la conexión', () async {
    net.setOnline(false);
    queue = buildQueue()..start();

    await queue.enqueue(event('VOCAL_A_TRAZO'));
    await queue.enqueue(event('VOCAL_E_TRAZO'));
    await queue.enqueue(event('FONEMA_M_PRACTICA'));
    await queue.flush(); // sin red: no debe salir nada

    expect(server.requests, isEmpty);
    final pending = await db.eventsByStatus(SyncStatus.pending);
    expect(pending, hasLength(3));
    expect(pending.every((e) => e.attempts == 0), isTrue);

    // Restaurar red → el listener dispara el flush; nos unimos a él.
    net.setOnline(true);
    await queue.flush();

    expect(server.requests, hasLength(1), reason: 'se envían en un solo lote');
    expect(
      server.acceptedEvents.map((e) => e['activity_id']),
      ['VOCAL_A_TRAZO', 'VOCAL_E_TRAZO', 'FONEMA_M_PRACTICA'],
    );
    final first = server.acceptedEvents.first;
    expect(first['child_id'], 1);
    expect(first['score'], 90);
    expect(first['stars'], 3);
    expect(first['metadata'], {'intentos': 1});
    expect(first['updated_at'], '2026-11-15T12:00:00.000Z');
    expect(first.containsKey('deleted_at'), isTrue);

    final synced = await db.eventsByStatus(SyncStatus.synced);
    expect(synced, hasLength(3));
    expect(synced.every((e) => e.syncedAt != null), isTrue);
    expect(await db.eventsByStatus(SyncStatus.pending), isEmpty);
  });

  test('fallo 500: el evento se reencola con backoff exponencial y luego se '
      'sincroniza', () async {
    server.scriptedStatuses.addAll([500, 500]); // luego 200
    queue = buildQueue()..start();
    final t0 = clock.now.millisecondsSinceEpoch;

    await queue.enqueue(event('VOCAL_I_TRAZO'));
    await queue.flush();

    // Intento 1 → 500 → reencolado a t0 + 2 s.
    expect(server.responseCodes, [500]);
    var row = (await db.allEvents()).single;
    expect(row.status, SyncStatus.pending);
    expect(row.attempts, 1);
    expect(row.nextAttemptAt, t0 + 2000);
    expect(row.lastError, contains('500'));
    expect(timers.last.delay, const Duration(seconds: 2));

    // Antes de que venza el backoff no se reintenta.
    await queue.flush();
    expect(server.requests, hasLength(1));

    // Intento 2 (t0 + 2 s) → 500 → reencolado con 4 s.
    clock.advance(const Duration(seconds: 2));
    timers.last.fire();
    await queue.flush();
    expect(server.responseCodes, [500, 500]);
    row = (await db.allEvents()).single;
    expect(row.attempts, 2);
    expect(row.nextAttemptAt, t0 + 2000 + 4000);
    expect(timers.last.delay, const Duration(seconds: 4));

    // Intento 3 (t0 + 6 s) → 200 → sincronizado.
    clock.advance(const Duration(seconds: 4));
    timers.last.fire();
    await queue.flush();
    expect(server.responseCodes, [500, 500, 200]);
    row = (await db.allEvents()).single;
    expect(row.status, SyncStatus.synced);
    expect(row.syncedAt, isNotNull);
    expect(server.acceptedEvents.single['activity_id'], 'VOCAL_I_TRAZO');
    expect(timers.where((t) => t.isActive), isEmpty);
  });

  test('error permanente 422: el lote se marca failed y no se reintenta',
      () async {
    server.scriptedStatuses.add(422);
    queue = buildQueue()..start();

    await queue.enqueue(event('X'));
    await queue.flush();
    await queue.flush();

    expect(server.requests, hasLength(1));
    final row = (await db.allEvents()).single;
    expect(row.status, SyncStatus.failed);
    expect(timers.where((t) => t.isActive), isEmpty);
  });

  test('concurrencia: enqueues y flushes simultáneos envían cada evento '
      'exactamente una vez', () async {
    server.latency = const Duration(milliseconds: 15);
    queue = buildQueue(batchSize: 7)..start();

    await Future.wait([
      for (var i = 0; i < 40; i++) ...[
        queue.enqueue(event('ACT_$i')),
        if (i % 5 == 0) queue.flush(),
      ],
    ]);
    // Drenar lo que quede (unirse al flush en curso + rerun).
    await queue.flush();
    await queue.flush();

    final ids = server.acceptedEvents.map((e) => e['activity_id']).toList();
    expect(ids, hasLength(40));
    expect(ids.toSet(), hasLength(40), reason: 'sin duplicados');
    expect(await db.eventsByStatus(SyncStatus.synced), hasLength(40));
    expect(
      server.requests.every((r) => (r['events'] as List).length <= 7),
      isTrue,
    );
  });

  test('BackoffPolicy: crece exponencialmente con tope y jitter acotado', () {
    const p = BackoffPolicy(jitter: 0);
    expect(
      [1, 2, 3, 4, 5].map((n) => p.delayFor(n).inSeconds),
      [2, 4, 8, 16, 32],
    );
    expect(p.delayFor(20), const Duration(minutes: 5));

    const j = BackoffPolicy(jitter: 0.2);
    for (var i = 0; i < 100; i++) {
      final ms = j.delayFor(3).inMilliseconds;
      expect(ms, inInclusiveRange(6400, 9600));
    }
    queue = buildQueue(); // para tearDown
  });
}
