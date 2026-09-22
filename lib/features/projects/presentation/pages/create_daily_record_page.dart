import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  late DateTime _activityDate = widget.record?.date ?? DateTime.now();

  /// Fotografías recién capturadas/seleccionadas, aún no persistidas.
  final List<String> _tempPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_activityDate),
    );
    if (time == null) return;

    setState(() {
      _activityDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() => _tempPhotos.add(photo.path));
      }
    } catch (e) {
      debugPrint("Error al tomar foto: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo abrir la cámara: $e")),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 70);
      if (photos.isNotEmpty) {
        setState(() => _tempPhotos.addAll(photos.map((p) => p.path)));
      }
    } catch (e) {
      debugPrint("Error al seleccionar fotos: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo abrir la galería: $e")),
      );
    }
  }

  Future<void> _deleteExistingPhoto(DailyRecordPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar fotografía'),
        content: const Text('¿Seguro que deseas eliminar esta fotografía guardada?'),
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(dailyRecordRepositoryProvider).deletePhoto(photo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo eliminar la fotografía: $e")),
      );
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
          date: _activityDate,
          description: _descController.text,
          observations: Value(_obsController.text),
          updatedAt: DateTime.now(),
        );
        await repository.updateRecord(updated);
        if (_tempPhotos.isNotEmpty) {
          await repository.addPhotosToRecord(
            record: updated,
            tempPhotoPaths: _tempPhotos,
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro actualizado correctamente")),
        );
      } else {
        final record = DailyRecord(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          date: _activityDate,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: Colors.grey[50],
              title: const Text("Fecha y hora de la actividad"),
              subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(_activityDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Fotografías", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text("Cámara"),
                ),
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text("Galería"),
                ),
              ],
            ),
            if (widget.isEditing) _buildExistingPhotosSection(),
            if (_tempPhotos.isNotEmpty) ...[
              if (widget.isEditing)
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    "Nuevas fotografías (se guardarán al confirmar)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
              _buildPhotoGrid(
                count: _tempPhotos.length,
                imageBuilder: (i) => Image.file(File(_tempPhotos[i]), fit: BoxFit.cover),
                onDelete: (i) => setState(() => _tempPhotos.removeAt(i)),
              ),
            ] else if (!widget.isEditing) ...[
              const SizedBox(height: 12),
              Text(
                "Sin fotografías todavía. Usa Cámara o Galería para agregar.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

  Widget _buildExistingPhotosSection() {
    final photosAsync = ref.watch(dailyRecordPhotosProvider(widget.record!.id));
    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                "Fotografías guardadas",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
            _buildPhotoGrid(
              count: photos.length,
              imageBuilder: (i) => Image.file(File(photos[i].localPath), fit: BoxFit.cover),
              onDelete: (i) => _deleteExistingPhoto(photos[i]),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text("Error al cargar fotografías: $e", style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildPhotoGrid({
    required int count,
    required Widget Function(int index) imageBuilder,
    required void Function(int index) onDelete,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: count,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageBuilder(index),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                onPressed: () => onDelete(index),
              ),
            ),
          ],
        );
      },
    );
  }
}
