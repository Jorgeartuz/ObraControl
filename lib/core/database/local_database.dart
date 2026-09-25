import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../sync/domain/sync_status.dart';

part 'local_database.g.dart';

// --- TABLAS ---
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
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
}

@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()();
  TextColumn get createdBy => text().nullable()(); // Campo consolidado
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyRecord')
class DailyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MaterialEntry')
class MaterialEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get materialName => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get supplier => text().nullable()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MaterialExit')
class MaterialExits extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get materialName => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get destination => text()();
  TextColumn get responsible => text().nullable()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Machine')
class Machinery extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyRecordPhoto')
class DailyRecordPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get dailyRecordId => text()();
  TextColumn get localPath => text()();
  TextColumn get storagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MachineryUsageLog')
class MachineryUsageLogs extends Table {
  TextColumn get id => text()();
  TextColumn get machineId => text()();
  TextColumn get projectId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get horometerStart => real()();
  RealColumn get horometerEnd => real()();
  RealColumn get hoursWorked => real()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DumpTruckLog')
class DumpTruckLogs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get plate => text()();
  TextColumn get driver => text()();
  TextColumn get material => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get entryTime => dateTime()();
  DateTimeColumn get exitTime => dateTime().nullable()();
  TextColumn get observations => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  IntColumn get syncStatus =>
      integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Espejo local de `public.project_members` (Supabase). Solo lectura desde
/// el punto de vista de la app: se llena vía pull (`pullProjectMembers`),
/// nunca se escribe localmente por acciones del usuario en este bloque
/// (compartir/gestionar miembros queda fuera de alcance por ahora).
@DataClassName('ProjectMember')
class ProjectMembers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get invitedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SyncQueue,
    Projects,
    DailyRecords,
    MaterialEntries,
    MaterialExits,
    Machinery,
    DailyRecordPhotos,
    MachineryUsageLogs,
    DumpTruckLogs,
    ProjectMembers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(projects);
      if (from < 3) {
        await m.createTable(dailyRecords);
        await m.createTable(materialEntries);
        await m.createTable(materialExits);
        await m.createTable(machinery);
      }
      if (from < 4) await m.createTable(dailyRecordPhotos);
      if (from < 5) {
        await m.addColumn(materialEntries, materialEntries.supplier);
      }
      if (from < 6) {
        await m.addColumn(materialExits, materialExits.responsible);
      }
      if (from < 7) {
        await m.addColumn(projects, projects.createdBy);
      }
      if (from < 8) {
        await m.addColumn(dailyRecords, dailyRecords.createdBy);
        await m.addColumn(materialEntries, materialEntries.createdBy);
        await m.addColumn(materialExits, materialExits.createdBy);
        await m.addColumn(machinery, machinery.createdBy);
        await m.addColumn(dailyRecordPhotos, dailyRecordPhotos.storagePath);
        await m.addColumn(dailyRecordPhotos, dailyRecordPhotos.createdBy);
      }
      if (from < 9) {
        await m.createTable(machineryUsageLogs);
        await m.createTable(dumpTruckLogs);
      }
      if (from < 10) {
        await m.createTable(projectMembers);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_project_members_project_id '
          'ON project_members (project_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_project_members_user_id '
          'ON project_members (user_id);',
        );
      }
    },
  );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'obra_control_db');
}
