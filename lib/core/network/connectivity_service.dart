import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<NetworkStatus> get connectivityStream {
    late final StreamController<NetworkStatus> controller;
    StreamSubscription<List<ConnectivityResult>>? subscription;
    Timer? timer;

    Future<void> emitStatus([List<ConnectivityResult>? results]) async {
      final currentResults = results ?? await _connectivity.checkConnectivity();
      final status =
          currentResults.isEmpty ||
              currentResults.contains(ConnectivityResult.none)
          ? NetworkStatus.offline
          : NetworkStatus.online;
      if (!controller.isClosed) controller.add(status);
    }

    controller = StreamController<NetworkStatus>(
      onListen: () {
        unawaited(emitStatus());
        subscription = _connectivity.onConnectivityChanged.listen(emitStatus);
        timer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => unawaited(emitStatus()),
        );
      },
      onCancel: () async {
        await subscription?.cancel();
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}

final connectivityServiceProvider = Provider((ref) => ConnectivityService());

final connectivityStreamProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).connectivityStream;
});
