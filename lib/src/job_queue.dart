import 'dart:collection';

import 'package:foreground_work_manager/src/job.dart';

/// Represents a queue of jobs that are executed in the order they are added.
///
/// A [JobQueue] contains:
/// - A unique identifier (`id`).
/// - A queue of [Job] instances (`queue`).
/// - A `process` callback that is invoked when a job in the queue is executed.
class JobQueue {
  /// Unique identifier for the queue.
  final String id;

  /// A queue of [Job] instances that are scheduled for execution.
  final Queue<Job> queue;

  /// A callback function that processes each job in the queue when it is executed.
  final Future<void> Function(Job) process;

  /// Creates a new [JobQueue] instance.
  ///
  /// Parameters:
  /// - `id`: A unique identifier for the queue.
  /// - `queue`: A queue of [Job] instances to be executed.
  /// - `process`: A callback function that processes each job in the queue.
  JobQueue({
    required this.id,
    required this.queue,
    required this.process,
  });

  /// Converts the [JobQueue] to a JSON-serializable map.
  ///
  /// This is used internally to store the queue in persistent storage.
  ///
  /// Returns:
  /// - A map containing the queue's `id` and a list of serialized jobs.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'queue': queue.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a [JobQueue] instance from a JSON-serializable map.
  ///
  /// This is used internally to restore queues from persistent storage.
  ///
  /// Parameters:
  /// - `map`: A map containing the queue's `id` and a list of serialized jobs.
  /// - `process`: A callback function that processes each job in the queue.
  ///
  /// Returns:
  /// - A new [JobQueue] instance.
  factory JobQueue.fromJson(
    Map<String, dynamic> map, {
    required Future<void> Function(Job) process,
  }) {
    return JobQueue(
      id: map['id'],
      queue: Queue.from((map['queue'] as List).map((e) => Job.fromJson(e))),
      process: process,
    );
  }
}
