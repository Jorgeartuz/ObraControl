import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../sync/domain/sync_status.dart';

part 'local_database.g.dart';

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

@DriftDatabase(tables: [SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    // driftDatabase es el método recomendado en versiones recientes para persistencia multiplataforma
    return driftDatabase(name: 'obra_control_db');
  }
}