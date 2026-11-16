import 'package:drift_flutter/drift_flutter.dart';
import 'package:http/http.dart' as http;

import 'connectivity_monitor.dart';
import 'sync_api_client.dart';
import 'sync_database.dart';
import 'sync_queue.dart';

/// Construye la cola de producción: SQLite en disco + red real.
SyncQueue createProductionSyncQueue({
  required Uri baseUrl,
  required Future<String?> Function() tokenProvider,
}) {
  final db = SyncDatabase(driftDatabase(name: 'leo_parvulos_sync'));
  final queue = SyncQueue(
    db: db,
    api: SyncApiClient(
      baseUrl: baseUrl,
      httpClient: http.Client(),
      tokenProvider: tokenProvider,
    ),
    connectivity: PlatformConnectivityMonitor(),
  );
  queue.start();
  return queue;
}
