import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/daily_records/data/daily_record_repository.dart';
import 'create_daily_record_page.dart';
import 'daily_record_detail_page.dart';

class DailyRecordsListPage extends ConsumerWidget {
  final Project project;
  
  const DailyRecordsListPage({
    super.key, 
    required this.project
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el stream de registros filtrados por el ID de esta obra
    // watchRecords es la función que definimos en el repositorio
    final recordsStream = ref.watch(dailyRecordRepositoryProvider).watchRecords(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text("Registros: ${project.name}"),
        elevation: 2,
      ),
      body: StreamBuilder<List<DailyRecord>>(
        stream: recordsStream,
        builder: (context, snapshot) {
          // 1. Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Manejo de error
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar registros: ${snapshot.error}"));
          }

          final records = snapshot.data ?? [];

          // 3. Estado vacío
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_roll_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "No hay registros diarios",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text("Toca el botón + para documentar hoy."),
                ],
              ),
            );
          }

          // 4. Lista de registros encontrados
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final dateFormatted = DateFormat('dd/MM/yyyy - HH:mm').format(record.date);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: Text(
                    record.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        dateFormatted,
                        style: TextStyle(color: Colors.blueGrey[600], fontSize: 13),
                      ),
                      if (record.observations != null && record.observations!.isNotEmpty)
                        Text(
                          record.observations!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navegar al detalle del registro para ver las fotos en grande
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyRecordDetailPage(record: record),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // Botón flotante para crear un nuevo registro diario
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateDailyRecordPage(projectId: project.id),
            ),
          );
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text("Nuevo Registro"),
      ),
    );
  }
}