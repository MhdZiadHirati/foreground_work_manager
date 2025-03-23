import 'dart:async';

import 'package:async/async.dart';
import 'package:foreground_work_manager/src/foreground_work_manager_base.dart';

/// Extension to convert [DueBehavior] enum values to their string representations.
///
/// This is used internally to serialize [DueBehavior] for storage and retrieval.
extension DueBehaviorToString on DueBehavior {
  /// Converts the [DueBehavior] enum to a string.
  ///
  /// Returns:
  /// - `"execute"` if the behavior is [DueBehavior.execute].
  /// - `"ignore"` if the behavior is [DueBehavior.ignore].
  String get asString {
    if (this == DueBehavior.execute) return "execute";
    if (this == DueBehavior.ignore) return "ignore";
    return "ignore";
  }
}

/// Converts a string representation of [DueBehavior] back to the [DueBehavior] enum.
///
/// Parameters:
/// - `value`: The string value to convert. Expected values are `"execute"` or `"ignore"`.
///
/// Returns:
/// - [DueBehavior.execute] if the input is `"execute"`.
/// - [DueBehavior.ignore] if the input is `"ignore"` or any other value.
DueBehavior dueBehaviorFromString(String value) {
  if (value == "execute") return DueBehavior.execute;
  if (value == "ignore") return DueBehavior.ignore;
  return DueBehavior.ignore;
}

/// Represents a job that can be scheduled and executed by [FGWorkManager].
///
/// A job contains:
/// - A unique identifier (`id`).
/// - A scheduled execution time (`time`).
/// - Optional data (`data`) to pass to the job's execution logic.
/// - A behavior (`dueBehavior`) to determine what happens if the job is past-due after an app restart.
class Job {
  /// Unique identifier for the job.
  final String id;

  /// The scheduled time for the job to execute.
  final DateTime time;

  /// Optional data associated with the job.
  final Map<String, dynamic>? data;

  /// Determines the behavior of the job if it is past-due after an app restart.
  final DueBehavior dueBehavior;

  /// Internal operation used to manage the job's execution.
  CancelableOperation? _operation;

  /// Internal flag to track if the job has been canceled.
  bool _canceled = false;

  /// Creates a new [Job] instance.
  ///
  /// Parameters:
  /// - `id`: A unique identifier for the job.
  /// - `time`: The scheduled execution time for the job.
  /// - `data`: Optional data to pass to the job's execution logic.
  /// - `dueBehavior`: Determines what happens if the job is past-due after an app restart.
  ///   Defaults to [DueBehavior.execute].
  Job({
    required this.id,
    required this.time,
    this.data,
    this.dueBehavior = DueBehavior.execute,
  });

  /// Whether the job has been canceled.
  bool get isCanceled => _canceled;

  /// Sets the internal [CancelableOperation] for the job.
  ///
  /// This is used internally to manage the job's execution lifecycle.
  void setOperation(CancelableOperation operation) {
    _operation = operation;
  }

  /// Cancels the job's execution.
  ///
  /// This marks the job as canceled and cancels the associated [CancelableOperation].
  Future<void> cancelOperation() async {
    _canceled = true;
    await _operation!.cancel();
  }

  /// Converts the job to a JSON-serializable map.
  ///
  /// This is used internally to store the job in persistent storage.
  ///
  /// Returns:
  /// - A map containing the job's `id`, `time`, `data`, and `dueBehavior`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'time': time.millisecondsSinceEpoch,
      if (data != null) 'data': data,
      "due_behavior": dueBehavior.asString,
    };
  }

  /// Creates a [Job] instance from a JSON-serializable map.
  ///
  /// This is used internally to restore jobs from persistent storage.
  ///
  /// Parameters:
  /// - `map`: A map containing the job's `id`, `time`, `data`, and `dueBehavior`.
  ///
  /// Returns:
  /// - A new [Job] instance.
  factory Job.fromJson(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int),
      data: map['data'],
      dueBehavior: dueBehaviorFromString(map["due_behavior"]),
    );
  }
}
