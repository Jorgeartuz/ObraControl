import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // En la v6 de connectivity_plus, onConnectivityChanged devuelve una List<ConnectivityResult>
  Stream<NetworkStatus> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) {
        if (results.isEmpty || results.contains(ConnectivityResult.none)) {
          return NetworkStatus.offline;
        }
        return NetworkStatus.online;
      });
}

final connectivityServiceProvider = Provider((ref) => ConnectivityService());

final connectivityStreamProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).connectivityStream;
});