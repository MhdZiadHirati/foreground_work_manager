import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:foreground_work_manager/src/cache_manager.dart';
import 'package:foreground_work_manager/src/job.dart';
import 'package:foreground_work_manager/src/job_queue.dart';

/// Defines the behavior for jobs that are past-due after an app restart.
///
/// This enum is used to determine how a job should be handled if its scheduled
/// execution time has passed while the app was closed or not running.
enum DueBehavior {
  /// The job should be executed immediately when the app is reopened.
  execute,

  /// The job should be ignored and discarded when the app is reopened.
  ignore,
}

/// The main class for managing foreground jobs in Flutter.
///
/// This class provides methods to:
/// - Initialize the job manager.
/// - Open, clear, and remove job queues.
/// - Add and remove jobs from queues.
/// - Handle job execution and scheduling.
///
/// Jobs are executed in the foreground, and their state is persisted across app restarts.
class FGWorkManager {
  /// Internal map to store active job queues by their unique IDs.
  static final Map<String, JobQueue> _queuesMap = {};

  /// Flag to track whether the manager has been initialized.
  static bool _init = false;

  /// Initializes the FGWorkManager.
  ///
  /// This method must be called before using any other functionality of the class.
  /// It initializes the cache manager for persistent storage.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.init();
  /// ```
  static Future<void> init() async {
    await CacheManager.init();
    _init = true;
  }

  /// Opens a new job queue with the specified ID and process callback.
  ///
  /// Parameters:
  /// - `queueId`: A unique identifier for the queue.
  /// - `process`: A callback function that processes each job in the queue.
  ///
  /// Throws:
  /// - An exception if the queue ID is not unique or if `init()` was not called.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.openQueue(
  ///   queueId: "testQueue",
  ///   process: (job) async {
  ///     print("Job executed: ${job.id}");
  ///   },
  /// );
  /// ```
  static Future<void> openQueue({
    required String queueId,
    required Future<void> Function(Job) process,
  }) async {
    if (_queuesMap.keys.contains(queueId)) {
      throw Exception("QUEUE IS ALREADY OPENED : THE QUEUE ID MUST BE UNIQUE");
    }
    if (!_init) {
      throw Exception(
          "FGWorkManager.init() WAS NOT CALLED. TRY TO CALL FGWorkManager.init() FIRST");
    }

    Queue<Job>? cachedQueue = CacheManager.getCachedQueue(jobQueueId: queueId);

    JobQueue? jobQueue;

    if (cachedQueue == null) {
      jobQueue = JobQueue(
        id: queueId,
        queue: Queue<Job>(),
        process: process,
      );

      await CacheManager.cacheQueue(jobQueue);
    } else {
      jobQueue = JobQueue(
        id: queueId,
        queue: cachedQueue,
        process: process,
      );
    }

    _queuesMap[queueId] = jobQueue;

    await _initQueueFutures(jobQueue);
  }

  /// Clears all jobs from a queue.
  ///
  /// Parameters:
  /// - `queueId`: The unique identifier of the queue to clear.
  ///
  /// Throws:
  /// - An exception if the queue ID is not found.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.clearQueue("testQueue");
  /// ```
  static Future<void> clearQueue(String queueId) async {
    if (!_queuesMap.keys.contains(queueId)) {
      throw Exception(
          "QUEUE WITH ID:$queueId WAS NOT OPENED : YOU SHOULD CALL FGWorkManager.openQueue FIRST");
    }

    await Future.wait(
      _queuesMap[queueId]!.queue.map((e) => e.cancelOperation()),
    );

    _queuesMap[queueId]!.queue.clear();

    await CacheManager.cacheQueue(_queuesMap[queueId]!);
  }

  /// Removes a queue and all its jobs.
  ///
  /// Parameters:
  /// - `queueId`: The unique identifier of the queue to remove.
  ///
  /// Throws:
  /// - An exception if the queue ID is not found.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.removeQueue("testQueue");
  /// ```
  static Future<void> removeQueue(String queueId) async {
    if (!_queuesMap.keys.contains(queueId)) {
      throw Exception(
          "QUEUE WITH ID:$queueId WAS NOT OPENED : YOU SHOULD CALL FGWorkManager.openQueue FIRST");
    }

    await Future.wait(
      _queuesMap[queueId]!.queue.map((e) => e.cancelOperation()),
    );

    _queuesMap.remove(queueId);

    await CacheManager.removeQueue(queueId);
  }

  /// Initializes futures for all jobs in a queue.
  ///
  /// This method schedules the execution of each job in the queue based on its scheduled time.
  ///
  /// Parameters:
  /// - `jobQueue`: The queue containing the jobs to initialize.
  static Future<void> _initQueueFutures(JobQueue jobQueue) async {
    for (Job job in jobQueue.queue) {
      await _initJobFuture(job: job, queueId: jobQueue.id);
    }
  }

  /// Initializes the future for a single job.
  ///
  /// This method schedules the execution of a job based on its scheduled time.
  /// If the job is past-due, it is either executed or ignored based on its `dueBehavior`.
  ///
  /// Parameters:
  /// - `job`: The job to initialize.
  /// - `queueId`: The unique identifier of the queue containing the job.
  static Future<void> _initJobFuture({
    required Job job,
    required String queueId,
  }) async {
    if (job.time.isBefore(DateTime.now())) {
      if (job.dueBehavior == DueBehavior.execute) {
        await _queuesMap[queueId]!.process.call(job);
        _queuesMap[queueId]!.queue.remove(job);
        await CacheManager.cacheQueue(_queuesMap[queueId]!);
      }
    } else {
      CancelableOperation cancelableOperation = CancelableOperation.fromFuture(
        Future.delayed(
          job.time.difference(DateTime.now()),
          () async {
            if (job.isCanceled) return;
            await _queuesMap[queueId]!.process.call(job);

            _queuesMap[queueId]!.queue.remove(job);

            await CacheManager.cacheQueue(_queuesMap[queueId]!);
          },
        ),
      );

      job.setOperation(cancelableOperation);
    }
  }

  /// Adds a job to a queue.
  ///
  /// Parameters:
  /// - `queueId`: The unique identifier of the queue to add the job to.
  /// - `job`: The job to add.
  ///
  /// Throws:
  /// - An exception if the queue ID is not found.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.addJob(
  ///   "testQueue",
  ///   Job(
  ///     id: 'j_1',
  ///     time: DateTime.now().add(Duration(seconds: 3)),
  ///     data: {},
  ///   ),
  /// );
  /// ```
  static Future<void> addJob(String queueId, Job job) async {
    if (!_queuesMap.keys.contains(queueId)) {
      throw Exception(
          "QUEUE WITH ID:$queueId WAS NOT OPENED : YOU SHOULD CALL FGWorkManager.openQueue FIRST");
    }

    _queuesMap[queueId]!.queue.add(job);

    await _initJobFuture(job: job, queueId: queueId);

    await CacheManager.cacheQueue(_queuesMap[queueId]!);
  }

  /// Removes a job from a queue.
  ///
  /// Parameters:
  /// - `queueId`: The unique identifier of the queue to remove the job from.
  /// - `jobId`: The unique identifier of the job to remove.
  ///
  /// Throws:
  /// - An exception if the queue ID or job ID is not found.
  ///
  /// Example:
  /// ```dart
  /// await FGWorkManager.removeJob(
  ///   queueId: "testQueue",
  ///   jobId: 'j_1',
  /// );
  /// ```
  static Future<void> removeJob({
    required String queueId,
    required String jobId,
  }) async {
    if (!_queuesMap.keys.contains(queueId)) {
      throw Exception(
          "QUEUE WITH ID:$queueId WAS NOT OPENED : YOU SHOULD CALL FGWorkManager.openQueue FIRST");
    }
    Job? job;
    try {
      job = _queuesMap[queueId]!.queue.firstWhere((e) => e.id == jobId);
    } catch (err) {
      throw Exception(
          "QUEUE WITH ID:$queueId DOES NOT CONTAIN A JOB WITH ID:$jobId");
    }

    await job.cancelOperation();

    _queuesMap[queueId]!.queue.remove(job);

    await CacheManager.cacheQueue(_queuesMap[queueId]!);
  }
}
