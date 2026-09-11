import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';

class MaterialExitDetailPage extends StatelessWidget {
  final MaterialExit exit;
  const MaterialExitDetailPage({super.key, required this.exit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de salida")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildField("Material", exit.materialName),
          _buildField("Cantidad", "${exit.quantity} ${exit.unit}"),
          _buildField("Fecha", DateFormat('dd/MM/yyyy').format(exit.date)),
          _buildField("Hora", DateFormat('HH:mm').format(exit.date)),
          _buildField("Destino", exit.destination),
          if (exit.responsible != null) _buildField("Responsable", exit.responsible!),
          if (exit.observations != null) _buildField("Observaciones", exit.observations!),
          const SizedBox(height: 20),
          const Text("Estado de sincronización", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StatusBadge(status: exit.syncStatus),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}