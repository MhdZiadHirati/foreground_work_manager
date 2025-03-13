import 'dart:async';

import 'package:async/async.dart';
import 'package:foreground_work_manager/src/foreground_work_manager_base.dart';

extension DueBehaviorToString on DueBehavior {
  String get asString {
    if (this == DueBehavior.execute) return "execute";
    if (this == DueBehavior.ignore) return "ignore";
    return "ignore";
  }
}

DueBehavior dueBehaviorFromString(String value) {
  if (value == "execute") return DueBehavior.execute;
  if (value == "ignore") return DueBehavior.ignore;
  return DueBehavior.ignore;
}

class Job {
  String id;
  DateTime time;
  Map<String, dynamic>? data;
  DueBehavior dueBehavior;
  CancelableOperation? _operation;
  bool _canceled = false;

  Job({
    required this.id,
    required this.time,
    this.data,
    this.dueBehavior = DueBehavior.execute,
  });

  bool get isCanceled => _canceled;

  void setOperation(CancelableOperation operation) {
    _operation = operation;
  }

  Future<void> cancelOperation() async {
    _canceled = true;
    await _operation!.cancel();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'time': time.millisecondsSinceEpoch,
      if (data != null) 'data': data,
      "due_behavior": dueBehavior.asString,
    };
  }

  factory Job.fromJson(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int),
      data: map['data'],
      dueBehavior: dueBehaviorFromString(map["due_behavior"]),
    );
  }
}
