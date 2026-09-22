import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_usage_repository.dart';

class AddMachineryUsagePage extends ConsumerStatefulWidget {
  final Machine machine;
  const AddMachineryUsagePage({super.key, required this.machine});

  @override
  ConsumerState<AddMachineryUsagePage> createState() => _AddMachineryUsagePageState();
}

class _AddMachineryUsagePageState extends ConsumerState<AddMachineryUsagePage> {
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _obsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  double? get _hoursWorked {
    final start = double.tryParse(_startController.text);
    final end = double.tryParse(_endController.text);
    if (start == null || end == null || end < start) return null;
    return double.parse((end - start).toStringAsFixed(2));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(machineryUsageRepositoryProvider).addUsageLog(
        machineId: widget.machine.id,
        projectId: widget.machine.projectId,
        date: _selectedDate,
        horometerStart: double.parse(_startController.text),
        horometerEnd: double.parse(_endController.text),
        observations: _obsController.text.trim().isEmpty ? null : _obsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uso de maquinaria registrado correctamente")),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: Text("Registrar uso: ${widget.machine.name}")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: Colors.grey[50],
              title: const Text("Fecha"),
              subtitle: Text(
                "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Horómetro inicial (h) *",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return "Debe ser un número válido ≥ 0";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Horómetro final (h) *",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return "Debe ser un número válido ≥ 0";
                final start = double.tryParse(_startController.text);
                if (start != null && n < start) {
                  return "No puede ser menor que el horómetro inicial";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _hoursWorked != null
                        ? "Horas trabajadas: ${_hoursWorked!.toStringAsFixed(2)} h"
                        : "Horas trabajadas: --",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
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
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text("GUARDAR REGISTRO DE USO"),
            ),
          ],
        ),
      ),
    );
  }
}
