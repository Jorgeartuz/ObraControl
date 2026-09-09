import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PhotoStorageService {
  Future<String> savePhotoPermanently(String tempPath, String dailyRecordId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final directoryPath = p.join(appDocDir.path, 'obra_control', 'daily_records', dailyRecordId);
    
    // Crear directorio si no existe
    await Directory(directoryPath).create(recursive: true);
    
    final fileName = p.basename(tempPath);
    final permanentPath = p.join(directoryPath, fileName);
    
    // Mover archivo
    await File(tempPath).copy(permanentPath);
    return permanentPath;
  }
}