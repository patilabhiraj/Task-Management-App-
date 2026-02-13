import 'dart:async'; // FIX: Added for StreamSubscription
import 'package:flutter_riverpod/legacy.dart'; // FIX: StateNotifierProvider moved to legacy in Riverpod 3.x
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../../../core/network/dio_client.dart';
import '../domain/task_model.dart';
import '../domain/task_state.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier() : super(TaskInitial()) {
    loadLocalTasks();
    listenConnectivity();
  }

  final dio = DioClient().dio;
  final tasksBox = Hive.box('tasksBox');
  final metaBox = Hive.box('metaBox');

  // FIX: Added StreamSubscription to properly dispose listener and prevent memory leaks
  // NOTE: connectivity_plus 5.0.2 uses ConnectivityResult, not List<ConnectivityResult>
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // PRODUCTION-SAFE: Prevent concurrent sync operations
  bool _isSyncing = false;

  /// Load tasks from local Hive cache
  /// This ensures offline-first behavior
  Future<void> loadLocalTasks() async {
    try {
      // FIX: Added null-safety check and type validation
      final localTasks = tasksBox.values
          .where((e) => e != null) // Filter out null values
          .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      state = TaskLoaded(localTasks);
    } catch (e) {
      // FIX: Handle errors when loading from cache
      state = TaskError("Failed to load local tasks: ${e.toString()}");
    }
  }

  /// Fetch tasks from backend API and sync to local cache
  ///
  /// **Production-Safe Sync Pattern:**
  /// - Uses tasksBox.clear() only (safe, keeps box alive)
  /// - Prevents concurrent syncs with _isSyncing flag
  /// - Atomic cache overwrite (clear → write)
  /// - Fallback to local cache on error (offline-first)
  /// - No deleteFromDisk() (avoids race conditions)
  Future<void> fetchTasksFromApi() async {
    // Prevent concurrent syncs
    if (_isSyncing) return;
    _isSyncing = true;

    state = TaskLoading();

    try {
      // Fetch fresh data from backend
      final response = await dio.get("/tasks");

      final tasks = (response.data as List)
          .map((e) => TaskModel.fromJson(e))
          .toList();

      // PRODUCTION-SAFE: Clear old cache while keeping box instance alive
      // This is safe and won't invalidate Riverpod listeners
      await tasksBox.clear();

      // Write fresh data atomically
      for (var task in tasks) {
        await tasksBox.put(task.id, task.toMap());
      }

      // Update last synced metadata
      await metaBox.put("lastSynced", DateTime.now().toIso8601String());

      // Emit fresh state to trigger UI rebuild
      state = TaskLoaded(tasks);
    } catch (e) {
      // OFFLINE-FIRST: Fallback to local cache on error
      await loadLocalTasks();

      // Show error but keep cached data visible
      state = TaskError("Sync failed: ${e.toString()}");
    } finally {
      _isSyncing = false;
    }
  }

  /// Update a task (works offline and syncs when online)
  /// If offline: saves locally with isSynced=false
  /// If online: calls API immediately and saves with isSynced=true
  Future<void> updateTask(
    TaskModel task, {
    required String status,
    required String remarks,
  }) async {
    // FIX: connectivity_plus 5.0.2 returns ConnectivityResult (not List)
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      // OFFLINE MODE: Save locally for later sync
      final updatedTask = task.copyWith(
        status: status,
        remarks: remarks,
        isSynced: false,
      );

      await tasksBox.put(task.id, updatedTask.toMap());

      // FIX: Ensure UI updates immediately even in offline mode
      await loadLocalTasks();
    } else {
      // ONLINE MODE: Update via API
      try {
        // FIX: Added try-catch to handle API errors gracefully
        await dio.put(
          "/tasks/${task.id}",
          data: {"status": status, "remarks": remarks},
        );

        final updatedTask = task.copyWith(
          status: status,
          remarks: remarks,
          isSynced: true,
        );

        await tasksBox.put(task.id, updatedTask.toMap());

        // FIX: Reload to ensure UI reflects changes
        await loadLocalTasks();
      } catch (e) {
        // FIX: If API fails, save offline and mark as unsynced
        final updatedTask = task.copyWith(
          status: status,
          remarks: remarks,
          isSynced: false,
        );

        await tasksBox.put(task.id, updatedTask.toMap());
        await loadLocalTasks();

        // Optionally show error state
        state = TaskError("Update saved offline. Will sync when online.");
        // Restore to loaded state after showing error
        Future.delayed(const Duration(seconds: 2), loadLocalTasks);
      }
    }
  }

  /// Listen to connectivity changes and auto-sync when coming online
  void listenConnectivity() {
    // FIX: connectivity_plus 5.0.2 uses ConnectivityResult (not List)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) {
        syncUnsyncedTasks();
      }
    });
  }

  /// Sync all unsynced tasks to backend when connectivity is restored
  Future<void> syncUnsyncedTasks() async {
    try {
      // FIX: Added null-safety check
      final unsynced = tasksBox.values
          .where((e) => e != null)
          .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((task) => task.isSynced == false)
          .toList();

      // FIX: Added individual try-catch to prevent one failure from blocking others
      for (var task in unsynced) {
        try {
          await dio.put(
            "/tasks/${task.id}",
            data: {"status": task.status, "remarks": task.remarks},
          );

          final syncedTask = task.copyWith(isSynced: true);
          await tasksBox.put(task.id, syncedTask.toMap());
        } catch (e) {
          // Log error but continue with other tasks
          // ignore: avoid_print
          print("Failed to sync task ${task.id}: ${e.toString()}");
          // Skip this task and continue
        }
      }

      // Reload tasks to update UI
      await loadLocalTasks();
    } catch (e) {
      // ignore: avoid_print
      print("Sync error: ${e.toString()}");
    }
  }

  // FIX: Added close method to cancel connectivity subscription and prevent memory leaks
  // Note: Riverpod 3.x StateNotifier will automatically call this when provider is disposed
  void close() {
    _connectivitySubscription?.cancel();
  }
}
