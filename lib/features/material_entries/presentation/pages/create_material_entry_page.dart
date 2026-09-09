import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/material_entries/data/material_entry_repository.dart';

class CreateMaterialEntryPage extends ConsumerStatefulWidget {
  final String projectId;
  const CreateMaterialEntryPage({super.key, required this.projectId});

  @override
  ConsumerState<CreateMaterialEntryPage> createState() => _CreateMaterialEntryPageState();
}

class _CreateMaterialEntryPageState extends ConsumerState<CreateMaterialEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _supplierController = TextEditingController();
  final _obsController = TextEditingController();
  
  String _selectedUnit = 'bultos';
  final List<String> _units = ['kg', 'toneladas', 'bultos', 'unidades', 'm', 'm²', 'm³', 'litros', 'Otra'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

    await ref.read(materialEntryRepositoryProvider).addEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar entrada")),
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
                    value: _selectedUnit,
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
                child: const Text("REGISTRAR ENTRADA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}