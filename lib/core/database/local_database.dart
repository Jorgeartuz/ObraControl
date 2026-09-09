import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../sync/domain/sync_status.dart';

part 'local_database.g.dart';

// --- 1. TABLA DE COLA DE SINCRONIZACIÓN (Paso 1) ---
@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); 
  TextColumn get entityId => text()();   
  TextColumn get action => text()();     
  TextColumn get payload => text()();    
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
}

// --- 2. TABLA DE PROYECTOS/OBRAS (Paso 2) ---
@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()(); // 'activa', 'finalizada'
  @override
  Set<Column> get primaryKey => {id};
}

// --- 3. TABLA DE REGISTROS DIARIOS (Paso 3) ---
@DataClassName('DailyRecord')
class DailyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 4. TABLA DE ENTRADA DE MATERIALES (Paso 3) ---
@DataClassName('MaterialEntry')
class MaterialEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get materialName => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get supplier => text().nullable()(); // Campo nuevo
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 5. TABLA DE SALIDA DE MATERIALES (Paso 3) ---
@DataClassName('MaterialExit')
class MaterialExits extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get materialName => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get destination => text()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 6. TABLA DE MAQUINARIA (Paso 3) ---
@DataClassName('Machine')
class Machinery extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 7. TABLA DE FOTOS DE REGISTROS (Paso 4 - NUEVA) ---
@DataClassName('DailyRecordPhoto') // <--- Esto genera la clase que te faltaba
class DailyRecordPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get dailyRecordId => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- CONFIGURACIÓN DE LA BASE DE DATOS ---

@DriftDatabase(tables: [
  SyncQueue, 
  Projects, 
  DailyRecords, 
  MaterialEntries, 
  MaterialExits, 
  Machinery, 
  DailyRecordPhotos
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Incrementamos la versión a 4 por la nueva tabla de fotos
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(projects);
      }
      if (from < 3) {
        await m.createTable(dailyRecords);
        await m.createTable(materialEntries);
        await m.createTable(materialExits);
        await m.createTable(machinery);
      }
      if (from < 4) {
        // Migración para el Paso 4: Agregar tabla de fotos
        await m.createTable(dailyRecordPhotos);
      }
      if (from < 5) {
      await m.addColumn(materialEntries, materialEntries.supplier);
    }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'obra_control_db');
  }
}