import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstracción del estado de red para poder simularlo en tests.
abstract class ConnectivityMonitor {
  Future<bool> isOnline();

  /// Emite `true`/`false` cuando cambia el estado de conectividad.
  Stream<bool> get onStatusChange;
}

/// Implementación real basada en `connectivity_plus`.
class PlatformConnectivityMonitor implements ConnectivityMonitor {
  PlatformConnectivityMonitor([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}
