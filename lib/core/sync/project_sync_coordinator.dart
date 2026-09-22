import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_engine.dart';

class ProjectSyncCoordinator {
  ProjectSyncCoordinator(this._syncEngine, this._pullProjects);

  final SyncEngine _syncEngine;
  final Future<void> Function() _pullProjects;
  bool _isSyncing = false;

  Future<void> syncIfPossible() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.isEmpty ||
          connectivity.contains(ConnectivityResult.none)) {
        return;
      }

      if (Supabase.instance.client.auth.currentUser == null) return;

      if (!await _canReachSupabase()) return;

      await _syncEngine.restoreConnectivityFailures();
      await _syncEngine.processSyncQueue();
      await _pullProjects();
    } catch (error) {
      debugPrint('Project sync error: $error');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _canReachSupabase() async {
    try {
      await Supabase.instance.client
          .from('projects')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } on TimeoutException {
      debugPrint('Supabase reachability check timed out.');
      return false;
    } catch (error) {
      debugPrint('Supabase is not reachable for project sync: $error');
      return false;
    }
  }
}
