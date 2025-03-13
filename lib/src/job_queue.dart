import 'dart:collection';

import 'package:foreground_work_manager/src/job.dart';

class JobQueue {
  String id;
  Queue<Job> queue;
  Future<void> Function(Job) process;

  JobQueue({
    required this.id,
    required this.queue,
    required this.process,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'queue': queue.map((e) => e.toJson()).toList(),
    };
  }

  factory JobQueue.fromJson(Map<String, dynamic> map,
      {required Future<void> Function(Job) process}) {
    return JobQueue(
      id: map['id'],
      queue: Queue.from((map['queue'] as List).map((e) => Job.fromJson(e))),
      process: process,
    );
  }
}
