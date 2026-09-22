import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/dump_trucks/data/dump_truck_repository.dart';

class CreateDumpTruckPage extends ConsumerStatefulWidget {
  final String projectId;
  final DumpTruckLog? log;
  const CreateDumpTruckPage({super.key, required this.projectId, this.log});

  bool get isEditing => log != null;

  @override
  ConsumerState<CreateDumpTruckPage> createState() => _CreateDumpTruckPageState();
}

class _CreateDumpTruckPageState extends ConsumerState<CreateDumpTruckPage> {
  final _formKey = GlobalKey<FormState>();
  late final _plateController = TextEditingController(text: widget.log?.plate);
  late final _driverController = TextEditingController(text: widget.log?.driver);
  late final _materialController = TextEditingController(text: widget.log?.material);
  late final _qtyController = TextEditingController(text: widget.log?.quantity.toString());
  late final _obsController = TextEditingController(text: widget.log?.observations);

  late DateTime _entryTime = widget.log?.entryTime ?? DateTime.now();
  late String _selectedUnit = widget.log?.unit ?? 'm³';
  final List<String> _units = ['m³', 'toneladas', 'kg', 'viajes'];
  bool _isSaving = false;

  @override
  void dispose() {
    _plateController.dispose();
    _driverController.dispose();
    _materialController.dispose();
    _qtyController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _pickEntryTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entryTime),
    );
    if (time == null) return;

    setState(() {
      _entryTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(dumpTruckRepositoryProvider);
      final observations = _obsController.text.trim().isEmpty ? null : _obsController.text.trim();

      if (widget.isEditing) {
        final existing = widget.log!;
        final updated = existing.copyWith(
          plate: _plateController.text.trim().toUpperCase(),
          driver: _driverController.text.trim(),
          material: _materialController.text.trim(),
          quantity: double.parse(_qtyController.text),
          unit: _selectedUnit,
          date: DateTime(_entryTime.year, _entryTime.month, _entryTime.day),
          entryTime: _entryTime,
          observations: Value(observations),
        );
        await repository.updateLog(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro de volqueta actualizado")),
        );
      } else {
        final log = DumpTruckLog(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          plate: _plateController.text.trim().toUpperCase(),
          driver: _driverController.text.trim(),
          material: _materialController.text.trim(),
          quantity: double.parse(_qtyController.text),
          unit: _selectedUnit,
          date: DateTime(_entryTime.year, _entryTime.month, _entryTime.day),
          entryTime: _entryTime,
          observations: observations,
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await repository.registerEntry(log);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entrada de volqueta registrada")),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Editar registro de volqueta" : "Registrar entrada de volqueta"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "Placa *", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Campo obligatorio" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _driverController,
              decoration: const InputDecoration(labelText: "Conductor *", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Campo obligatorio" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(labelText: "Material *", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Campo obligatorio" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Cantidad *", border: OutlineInputBorder()),
                    validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? "Mayor a 0" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(labelText: "Unidad", border: OutlineInputBorder()),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Fecha y hora de entrada"),
              subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(_entryTime)),
              trailing: const Icon(Icons.calendar_today),
              tileColor: Colors.grey[50],
              onTap: _pickEntryTime,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obsController,
              decoration: const InputDecoration(labelText: "Observaciones", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : Text(widget.isEditing ? "GUARDAR CAMBIOS" : "REGISTRAR ENTRADA"),
            ),
          ],
        ),
      ),
    );
  }
}
