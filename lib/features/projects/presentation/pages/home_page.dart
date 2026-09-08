import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/data/sync_repository.dart';
import '../../../../core/sync/domain/sync_status.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netStatus = ref.watch(connectivityStreamProvider);
    final syncRepo = ref.watch(syncRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ObraControl - Tech Base')),
      body: Column(
        children: [
          _ConnectivityBanner(status: netStatus),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Cola de Sincronización Local", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: syncRepo.watchQueue(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text("${item.entityType}: ${item.action}"),
                      subtitle: Text("UUID: ${item.entityId.substring(0,8)}"),
                      trailing: Chip(
                        label: Text(item.syncStatus.name, style: const TextStyle(fontSize: 10)),
                        backgroundColor: item.syncStatus == SyncStatus.synced ? Colors.green[100] : Colors.orange[100],
                      ),
                      onTap: () => syncRepo.updateStatus(item.id, SyncStatus.synced),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Simular Registro de Obra"),
              onPressed: () => syncRepo.addItem(
                'OBRA_DIARIA', 
                const Uuid().v4(), 
                'INSERT', 
                '{"proyecto": "Test"}'
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final AsyncValue<NetworkStatus> status;
  const _ConnectivityBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOnline = status.maybeWhen(data: (s) => s == NetworkStatus.online, orElse: () => false);
    return Container(
      color: isOnline ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      child: Text(
        isOnline ? "CONECTADO A RED" : "TRABAJANDO SIN CONEXIÓN",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}