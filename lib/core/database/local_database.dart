import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../sync/domain/sync_status.dart';

part 'local_database.g.dart';

// --- TABLA EXISTENTE (Paso 1) ---
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

// --- NUEVA TABLA (Paso 2) ---
@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()(); // 'active', 'finished', 'archived'

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SyncQueue, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Incrementamos la versión a 2
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Añadimos la tabla de proyectos sin borrar la de SyncQueue
        await m.createTable(projects);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'obra_control_db');
  }
}