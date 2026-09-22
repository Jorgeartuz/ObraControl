import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/material_exits/data/material_exit_repository.dart';

class CreateMaterialExitPage extends ConsumerStatefulWidget {
  final String projectId;
  final MaterialExit? exit;
  const CreateMaterialExitPage({super.key, required this.projectId, this.exit});

  bool get isEditing => exit != null;

  @override
  ConsumerState<CreateMaterialExitPage> createState() =>
      _CreateMaterialExitPageState();
}

class _CreateMaterialExitPageState
    extends ConsumerState<CreateMaterialExitPage> {
  final _formKey = GlobalKey<FormState>();
  late final _materialController = TextEditingController(text: widget.exit?.materialName);
  late final _qtyController = TextEditingController(text: widget.exit?.quantity.toString());
  late final _destinationController = TextEditingController(text: widget.exit?.destination);
  late final _responsibleController = TextEditingController(text: widget.exit?.responsible);
  late final _obsController = TextEditingController(text: widget.exit?.observations);

  late DateTime _selectedDate = widget.exit?.date ?? DateTime.now();
  late String _selectedUnit = widget.exit?.unit ?? 'bultos';
  final List<String> _units = [
    'kg',
    'toneladas',
    'bultos',
    'unidades',
    'm',
    'm²',
    'm³',
    'litros',
    'metros',
  ];

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(
      () => _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(materialExitRepositoryProvider);
    final responsible = _responsibleController.text.trim().isEmpty
        ? null
        : _responsibleController.text.trim();
    final observations = _obsController.text.trim().isEmpty
        ? null
        : _obsController.text.trim();

    if (widget.isEditing) {
      final existing = widget.exit!;
      final updated = MaterialExit(
        id: existing.id,
        projectId: existing.projectId,
        date: _selectedDate,
        materialName: _materialController.text.trim(),
        quantity: double.parse(_qtyController.text),
        unit: _selectedUnit,
        destination: _destinationController.text.trim(),
        responsible: responsible,
        observations: observations,
        createdAt: existing.createdAt,
        createdBy: existing.createdBy,
        syncStatus: SyncStatus.pending,
      );
      await repository.updateExit(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salida actualizada correctamente")),
      );
    } else {
      final exit = MaterialExit(
        id: const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        materialName: _materialController.text.trim(),
        quantity: double.parse(_qtyController.text),
        unit: _selectedUnit,
        destination: _destinationController.text.trim(),
        responsible: responsible,
        observations: observations,
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await repository.addExit(exit);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salida registrada correctamente")),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Editar salida" : "Registrar salida"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: "Material *",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Cantidad *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                        ? "Mayor a 0"
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: "Unidad",
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Fecha y Hora"),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              tileColor: Colors.grey[50],
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: "Destino *",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _responsibleController,
              decoration: const InputDecoration(
                labelText: "Responsable",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obsController,
              decoration: const InputDecoration(
                labelText: "Observaciones",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.isEditing ? "GUARDAR CAMBIOS" : "REGISTRAR SALIDA"),
            ),
          ],
        ),
      ),
    );
  }
}
