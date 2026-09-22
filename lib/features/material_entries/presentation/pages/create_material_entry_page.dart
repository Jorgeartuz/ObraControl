import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/material_entries/data/material_entry_repository.dart';

class CreateMaterialEntryPage extends ConsumerStatefulWidget {
  final String projectId;
  final MaterialEntry? entry;
  const CreateMaterialEntryPage({super.key, required this.projectId, this.entry});

  bool get isEditing => entry != null;

  @override
  ConsumerState<CreateMaterialEntryPage> createState() => _CreateMaterialEntryPageState();
}

class _CreateMaterialEntryPageState extends ConsumerState<CreateMaterialEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.entry?.materialName);
  late final _qtyController = TextEditingController(text: widget.entry?.quantity.toString());
  late final _supplierController = TextEditingController(text: widget.entry?.supplier);
  late final _obsController = TextEditingController(text: widget.entry?.observations);

  late String _selectedUnit = widget.entry?.unit ?? 'bultos';
  final List<String> _units = ['kg', 'toneladas', 'bultos', 'unidades', 'm', 'm²', 'm³', 'litros', 'Otra'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(materialEntryRepositoryProvider);
    if (widget.isEditing) {
      final existing = widget.entry!;
      final updated = MaterialEntry(
        id: existing.id,
        projectId: existing.projectId,
        date: existing.date,
        materialName: _nameController.text,
        quantity: double.parse(_qtyController.text),
        unit: _selectedUnit,
        supplier: _supplierController.text.isEmpty ? null : _supplierController.text,
        observations: _obsController.text.isEmpty ? null : _obsController.text,
        createdAt: existing.createdAt,
        createdBy: existing.createdBy,
        syncStatus: SyncStatus.pending,
      );
      await repository.updateEntry(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrada actualizada correctamente")),
      );
    } else {
      final entry = MaterialEntry(
        id: const Uuid().v4(),
        projectId: widget.projectId,
        date: DateTime.now(),
        materialName: _nameController.text,
        quantity: double.parse(_qtyController.text),
        unit: _selectedUnit,
        supplier: _supplierController.text.isEmpty ? null : _supplierController.text,
        observations: _obsController.text.isEmpty ? null : _obsController.text,
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await repository.addEntry(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? "Editar entrada" : "Registrar entrada")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre del material *", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Ingresa el nombre del material" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Cantidad *", border: OutlineInputBorder()),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return "Debe ser > 0";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(labelText: "Unidad *", border: OutlineInputBorder()),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(labelText: "Proveedor u origen", border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obsController,
              decoration: const InputDecoration(labelText: "Observaciones", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                child: Text(
                  widget.isEditing ? "GUARDAR CAMBIOS" : "REGISTRAR ENTRADA",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}