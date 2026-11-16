import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:leo_parvulos_app/sync/connectivity_monitor.dart';

/// Red simulada: permite "cortar" y "restaurar" la conexión en los tests.
class FakeConnectivity implements ConnectivityMonitor {
  FakeConnectivity({bool online = true}) : _online = online;

  bool _online;
  final _ctrl = StreamController<bool>.broadcast(sync: true);

  void setOnline(bool value) {
    if (value == _online) return;
    _online = value;
    _ctrl.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onStatusChange => _ctrl.stream;

  Future<void> close() => _ctrl.close();
}

/// Servidor HTTP real en localhost que imita `POST /api/sync/progress`.
class MockSyncServer {
  MockSyncServer._(this._server);

  final HttpServer _server;

  /// Códigos a devolver en orden; cuando se agota responde 200.
  final List<int> scriptedStatuses = [];

  /// Latencia artificial por petición (útil para forzar solapamientos).
  Duration latency = Duration.zero;

  /// Cuerpos de cada petición recibida (incluidas las fallidas).
  final List<Map<String, dynamic>> requests = [];

  /// Eventos aceptados (solo de respuestas 200).
  final List<Map<String, dynamic>> acceptedEvents = [];

  final List<int> responseCodes = [];

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<MockSyncServer> start() async {
    final s = MockSyncServer._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    s._server.listen(s._handle);
    return s;
  }

  Future<void> _handle(HttpRequest req) async {
    if (req.method != 'POST' || req.uri.path != '/api/sync/progress') {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final body =
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    requests.add(body);
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final status =
        scriptedStatuses.isEmpty ? 200 : scriptedStatuses.removeAt(0);
    responseCodes.add(status);
    final events = (body['events'] as List).cast<Map<String, dynamic>>();
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    if (status == 200) {
      acceptedEvents.addAll(events);
      req.response.write(jsonEncode({
        'message': 'Lote de progreso sincronizado exitosamente.',
        'summary': {'total_events': events.length, 'inserted': events.length},
      }));
    } else {
      req.response.write(jsonEncode({'message': 'Server Error'}));
    }
    await req.response.close();
  }

  Future<void> close() => _server.close(force: true);
}

/// Reloj controlable.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  void advance(Duration d) => now = now.add(d);
  DateTime call() => now;
}

/// Timer que no corre solo: el test decide cuándo dispararlo.
class FakeTimer implements Timer {
  FakeTimer(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
