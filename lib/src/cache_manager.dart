import 'dart:collection';
import 'dart:convert';

import 'package:foreground_work_manager/src/job.dart';
import 'package:foreground_work_manager/src/job_queue.dart';
import 'package:get_storage/get_storage.dart';

/// Manages the caching and retrieval of job queues using [GetStorage].
///
/// This class provides methods to:
/// - Initialize the cache storage.
/// - Cache a job queue.
/// - Retrieve a cached job queue.
/// - Remove a cached job queue.
///
/// It also supports a test mode to bypass storage operations during testing.
class CacheManager {
  /// Internal instance of [GetStorage] used for persistent storage.
  static late GetStorage _box;

  /// Flag to enable or disable test mode.
  /// When enabled, storage operations are bypassed.
  static bool _testMode = false;

  /// Enables or disables test mode.
  ///
  /// Parameters:
  /// - `mode`: If `true`, test mode is enabled, and storage operations are bypassed.
  static void setTestMode(bool mode) {
    _testMode = mode;
  }

  /// Initializes the cache storage.
  ///
  /// This method must be called before using any other functionality of [CacheManager].
  /// If test mode is enabled, initialization is skipped.
  static Future<void> init() async {
    if (_testMode) return;

    await GetStorage.init();
    _box = GetStorage();
  }

  /// Retrieves a cached job queue from storage.
  ///
  /// Parameters:
  /// - `jobQueueId`: The unique identifier of the job queue to retrieve.
  ///
  /// Returns:
  /// - A [Queue<Job>] containing the cached jobs, or `null` if no queue is found.
  static Queue<Job>? getCachedQueue({required String jobQueueId}) {
    if (_testMode) {
      return Queue.from([].map((e) => Job.fromJson(e)));
    }

    String? encodedJsonQueue = _box.read(jobQueueId);

    if (encodedJsonQueue == null) return null;

    Map<String, dynamic> cachedJson = jsonDecode(encodedJsonQueue);
    List list = cachedJson['list'];

    return Queue.from(list.map((e) => Job.fromJson(e)));
  }

  /// Caches a job queue in storage.
  ///
  /// Parameters:
  /// - `jobQueue`: The [JobQueue] to cache.
  ///
  /// If test mode is enabled, caching is skipped.
  static Future<void> cacheQueue(JobQueue jobQueue) async {
    if (_testMode) {
      return;
    }

    Map<String, dynamic> toCacheJson = {
      'list': jobQueue.queue.map((e) => e.toJson()).toList()
    };

    String encodedJson = jsonEncode(toCacheJson);

    await _box.write(jobQueue.id, encodedJson);
  }

  /// Removes a cached job queue from storage.
  ///
  /// Parameters:
  /// - `jobQueueId`: The unique identifier of the job queue to remove.
  ///
  /// If test mode is enabled, removal is skipped.
  static Future<void> removeQueue(String jobQueueId) async {
    if (_testMode) return;
    await _box.remove(jobQueueId);
  }
}
