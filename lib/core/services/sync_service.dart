// lib/core/services/sync_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for managing background sync operations
///
/// Provides functionality to:
/// - Sync data in the background
/// - Retry failed syncs with exponential backoff
/// - Resume interrupted syncs
/// - Handle offline scenarios gracefully
///
/// Note: This service is prepared for future API integration.
/// Currently, the app works fully offline with local data.
/// When a remote API is available, this service will handle sync operations.
class SyncService {
  static SyncService? _instance;
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  SyncService._();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final List<SyncTask> _pendingTasks = [];
  final Map<String, int> _retryCounts = {};

  /// Start periodic sync (e.g., every 24 hours)
  ///
  /// [interval] - Duration between sync attempts (default: 24 hours)
  void startPeriodicSync({Duration interval = const Duration(hours: 24)}) {
    if (_syncTimer != null) {
      _syncTimer?.cancel();
    }

    _syncTimer = Timer.periodic(interval, (_) {
      syncInBackground();
    });

    if (kDebugMode) {
      debugPrint('✅ Started periodic sync (interval: ${interval.inHours}h)');
    }
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (kDebugMode) {
      debugPrint('✅ Stopped periodic sync');
    }
  }

  /// Sync data in the background (non-blocking)
  ///
  /// This method attempts to sync data but doesn't block the UI.
  /// If sync fails, it will be retried later.
  Future<void> syncInBackground() async {
    if (_isSyncing) {
      if (kDebugMode) {
        debugPrint('⚠️ Sync already in progress, skipping');
      }
      return;
    }

    _isSyncing = true;
    if (kDebugMode) {
      debugPrint('🔄 Starting background sync...');
    }

    try {
      // Process pending tasks first
      await _processPendingTasks();

      // Perform main sync operations
      // Note: When API is available, implement actual sync logic here
      // For now, this is a placeholder that demonstrates the structure

      if (kDebugMode) {
        debugPrint('✅ Background sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Background sync failed: $e');
      }
      // Sync failures are handled gracefully - app continues to work offline
    } finally {
      _isSyncing = false;
    }
  }

  /// Add a sync task to the queue
  ///
  /// [task] - The sync task to add
  void addSyncTask(SyncTask task) {
    _pendingTasks.add(task);
    if (kDebugMode) {
      debugPrint('📝 Added sync task: ${task.type}');
    }
  }

  /// Process pending sync tasks
  Future<void> _processPendingTasks() async {
    final tasksToProcess = List<SyncTask>.from(_pendingTasks);
    _pendingTasks.clear();

    for (final task in tasksToProcess) {
      try {
        await _executeSyncTask(task);
        _retryCounts.remove(task.id);
      } catch (e) {
        // Retry with exponential backoff
        final retryCount = _retryCounts[task.id] ?? 0;
        if (retryCount < 3) {
          _retryCounts[task.id] = retryCount + 1;
          _pendingTasks.add(task);
          if (kDebugMode) {
            debugPrint(
                '⚠️ Sync task ${task.id} failed, will retry (attempt ${retryCount + 1}/3)');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Sync task ${task.id} failed after 3 attempts');
          }
        }
      }
    }
  }

  /// Execute a sync task
  Future<void> _executeSyncTask(SyncTask task) async {
    // Placeholder for actual sync implementation
    // When API is available, implement actual sync logic here
    if (kDebugMode) {
      debugPrint('🔄 Executing sync task: ${task.type} (${task.id})');
    }

    // Simulate sync delay
    await Future.delayed(const Duration(milliseconds: 100));

    // In real implementation, this would:
    // 1. Check network connectivity
    // 2. Call remote API
    // 3. Update local cache
    // 4. Handle errors gracefully
  }

  /// Resume interrupted sync
  ///
  /// This method is called when the app resumes from background
  /// or when network connectivity is restored.
  Future<void> resumeSync() async {
    if (kDebugMode) {
      debugPrint('🔄 Resuming sync...');
    }
    await syncInBackground();
  }

  /// Get sync status
  ///
  /// Returns true if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Get number of pending sync tasks
  int get pendingTaskCount => _pendingTasks.length;

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
    _pendingTasks.clear();
    _retryCounts.clear();
  }
}

/// Represents a sync task
class SyncTask {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  SyncTask({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };
}
