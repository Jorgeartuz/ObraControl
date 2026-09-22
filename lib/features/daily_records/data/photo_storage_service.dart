import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PhotoStorageService {
  /// Copia una foto temporal (cámara/galería) a almacenamiento permanente,
  /// organizada como obra/registro_diario/<id>/<fecha>/<uuid>.<ext>.
  /// El nombre original nunca se reutiliza, evitando colisiones y nombres ambiguos.
  Future<String> savePhotoPermanently({
    required String tempPath,
    required String projectId,
    required String dailyRecordId,
    required DateTime activityDate,
  }) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dateSegment = DateFormat('yyyy-MM-dd').format(activityDate);
    final directoryPath = p.join(
      appDocDir.path,
      'obra_control',
      projectId,
      'registro_diario',
      dailyRecordId,
      dateSegment,
    );

    await Directory(directoryPath).create(recursive: true);

    final extension = p.extension(tempPath).isEmpty ? '.jpg' : p.extension(tempPath);
    final fileName = '${const Uuid().v4()}$extension';
    final permanentPath = p.join(directoryPath, fileName);

    await File(tempPath).copy(permanentPath);
    return permanentPath;
  }

  /// Elimina un archivo de foto del almacenamiento local si existe.
  Future<void> deletePhoto(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Elimina el directorio completo de fotos de un registro diario (usado al
  /// borrar el registro). No falla si el directorio no existe.
  Future<void> deleteRecordFolder(String projectId, String dailyRecordId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final directoryPath = p.join(
      appDocDir.path,
      'obra_control',
      projectId,
      'registro_diario',
      dailyRecordId,
    );
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
