import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/daily_records/data/daily_record_repository.dart';

class CreateDailyRecordPage extends ConsumerStatefulWidget {
  final String projectId;
  final DailyRecord? record;
  const CreateDailyRecordPage({super.key, required this.projectId, this.record});

  bool get isEditing => record != null;

  @override
  ConsumerState<CreateDailyRecordPage> createState() => _CreateDailyRecordPageState();
}

class _CreateDailyRecordPageState extends ConsumerState<CreateDailyRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _descController = TextEditingController(text: widget.record?.description);
  late final _obsController = TextEditingController(text: widget.record?.observations);
  final List<String> _tempPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _takePhoto() async {
try {
      // 1. Asegúrate de tener el source:
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      // 2. Verifica si la variable photo es nula o no
      if (photo != null) {
        setState(() {
          _tempPhotos.add(photo.path);
        });
      }
    } catch (e) {
      // 3. Captura cualquier error de permisos o hardware
      debugPrint("Error al tomar foto: $e");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(dailyRecordRepositoryProvider);
      if (widget.isEditing) {
        final existing = widget.record!;
        final updated = existing.copyWith(
          description: _descController.text,
          observations: Value(_obsController.text),
          updatedAt: DateTime.now(),
        );
        await repository.updateRecord(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro actualizado correctamente")),
        );
      } else {
        final record = DailyRecord(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          date: DateTime.now(),
          description: _descController.text,
          observations: _obsController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await repository.saveCompleteRecord(
          record: record,
          tempPhotoPaths: _tempPhotos,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Editar Registro" : "Nuevo Registro"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Actividad Principal *", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obsController,
              decoration: const InputDecoration(labelText: "Observaciones", border: OutlineInputBorder()),
              maxLines: 2,
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 20),
              const Text("Fotografías", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _tempPhotos.length + 1,
                itemBuilder: (context, index) {
                  if (index == _tempPhotos.length) {
                    return InkWell(
                      onTap: _takePhoto,
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_tempPhotos[index]), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: IconButton(
                          icon: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                          onPressed: () => setState(() => _tempPhotos.removeAt(index)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: _isSaving
              ? const CircularProgressIndicator()
              : Text(widget.isEditing ? "GUARDAR CAMBIOS" : "GUARDAR REGISTRO"),
        ),
      ),
    );
  }
}