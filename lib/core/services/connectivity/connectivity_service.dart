import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Internet reachability (Phase 6 offline mode).
///
/// Wraps connectivity_plus. Note: this reports *network* connectivity,
/// not guaranteed internet — callers that need certainty should still
/// handle HTTP failures gracefully (all network features already do).
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _online = true;
  bool get isOnline => _online;

  /// Broadcasts whenever connectivity changes.
  Stream<bool> get onChange => _controller.stream;

  Future<void> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _update(results);
    } catch (_) {
      _online = true; // Unknown: assume online, fail gracefully later.
    }
    _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);
    if (online != _online) {
      _online = online;
      _controller.add(_online);
    }
  }

  void dispose() => _controller.close();
}
