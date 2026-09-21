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
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
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
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
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
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
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
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
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
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyRecordPhoto')
class DailyRecordPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get dailyRecordId => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().map(const EnumIndexConverter<SyncStatus>(SyncStatus.values))();
  @override
  Set<Column> get primaryKey => {id};
}

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

  @override
  int get schemaVersion => 7;

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
      if (from < 5) await m.addColumn(materialEntries, materialEntries.supplier);
      if (from < 6) await m.addColumn(materialExits, materialExits.responsible);
      if (from < 7) await m.addColumn(projects, projects.createdBy);
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'obra_control_db');
}