import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';
import 'package:obrafcontrol_test/features/daily_records/data/daily_record_repository.dart';
import 'create_daily_record_page.dart';

class DailyRecordDetailPage extends ConsumerWidget {
  final DailyRecord record;
  const DailyRecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(dailyRecordProvider(record.id));

    return recordAsync.when(
      data: (currentRecord) {
        if (currentRecord == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Detalle del Registro")),
            body: const Center(child: Text("Este registro ya no existe.")),
          );
        }
        return _DailyRecordDetailView(record: currentRecord);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text("Detalle del Registro")),
        body: Center(child: Text("Error al cargar el registro: $error")),
      ),
    );
  }
}

class _DailyRecordDetailView extends ConsumerWidget {
  final DailyRecord record;
  const _DailyRecordDetailView({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Registro"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar registro',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateDailyRecordPage(
                  projectId: record.projectId,
                  record: record,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar registro',
            onPressed: () => _deleteRecord(context, ref, record),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Título y Fecha
          Text(
            record.description,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            DateFormat('dd/MM/yyyy - HH:mm').format(record.date),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Divider(height: 40),

          // Observaciones
          const Text(
            "Observaciones:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (record.observations == null || record.observations!.isEmpty)
                  ? "Sin observaciones adicionales."
                  : record.observations!,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),

          // Galería de Fotos
          const Text(
            "Evidencia Fotográfica:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),

          ref.watch(dailyRecordPhotosProvider(record.id)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text("Error al cargar fotografías: $error"),
            data: (photos) {
              if (photos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Este registro no tiene fotografías asociadas."),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, photo.localPath),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(photo.localPath),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: StatusBadge(status: photo.syncStatus),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    DailyRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que deseas eliminar este registro diario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(dailyRecordRepositoryProvider).deleteRecord(record.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado correctamente.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el registro: $error')),
      );
    }
  }

  // Función sencilla para ver la foto en grande al tocarla
  void _showFullScreenImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(File(path)),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
