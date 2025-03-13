import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:foreground_work_manager/src/cache_manager.dart';
import 'package:foreground_work_manager/src/job.dart';
import 'package:foreground_work_manager/src/job_queue.dart';

enum DueBehavior { execute, ignore }

class FGWorkManager {
  static final Map<String, JobQueue> _queuesMap = {};

  static bool _init = false;

  static Future<void> init() async {
    await CacheManager.init();
    _init = true;
  }

  static Future<void> openQueue({
    required String queueId,
    required Future<void> Function(Job) process,
  }) async {
    if (_queuesMap.keys.contains(queueId)) {
      throw Exception("QUEUE IS ALREADY OPENED : THE QUEUE ID MUST BE UNIQUE");
    }
    if (!_init) {
      throw Exception(
          "FGWorkManager.init() WAS NOT CALLED.TRY TO CALL FGWorkManager.init() FIRST");
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

  static Future<void> _initQueueFutures(JobQueue jobQueue) async {
    for (Job job in jobQueue.queue) {
      await _initJobFuture(job: job, queueId: jobQueue.id);
    }
  }

  static Future<void> _initJobFuture(
      {required Job job, required String queueId}) async {
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

  static Future<void> addJob(String queueId, Job job) async {
    if (!_queuesMap.keys.contains(queueId)) {
      throw Exception(
          "QUEUE WITH ID:$queueId WAS NOT OPENED : YOU SHOULD CALL FGWorkManager.openQueue FIRST");
    }

    _queuesMap[queueId]!.queue.add(job);

    await _initJobFuture(job: job, queueId: queueId);

    await CacheManager.cacheQueue(_queuesMap[queueId]!);
  }

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
