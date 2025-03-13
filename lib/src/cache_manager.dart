import 'dart:collection';
import 'dart:convert';

import 'package:foreground_work_manager/src/job.dart';
import 'package:foreground_work_manager/src/job_queue.dart';
import 'package:get_storage/get_storage.dart';

class CacheManager {
  static late GetStorage box;

  static bool _testMode = false;

  static void setTestMode(bool mode) {
    _testMode = mode;
  }

  static Future<void> init() async {
    if (_testMode) return;

    await GetStorage.init();

    box = GetStorage();
  }

  static Queue<Job>? getCachedQueue({required String jobQueueId}) {
    if (_testMode) {
      return Queue.from([].map((e) => Job.fromJson(e)));
    }

    String? encodedJsonQueue = box.read(jobQueueId);

    if (encodedJsonQueue == null) return null;

    Map<String, dynamic> cachedJson = jsonDecode(encodedJsonQueue);

    List list = cachedJson['list'];

    return Queue.from(list.map((e) => Job.fromJson(e)));
  }

  static Future<void> cacheQueue(JobQueue jobQueue) async {
    if (_testMode) {
      return;
    }

    Map<String, dynamic> toCacheJson = {
      'list': jobQueue.queue.map((e) => e.toJson()).toList()
    };

    String encodedJson = jsonEncode(toCacheJson);

    await box.write(jobQueue.id, encodedJson);
  }

  static Future<void> removeQueue(String jobQueueId) async {
    if (_testMode) return;
    await box.remove(jobQueueId);
  }
}
