import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_work_manager/foreground_work_manager.dart';
import 'package:foreground_work_manager/src/cache_manager.dart';

void main() {
  setUp(
    () async {
      CacheManager.setTestMode(true);
      await FGWorkManager.init();
    },
  );

  test("Should open a queue and add jobs", () async {
    final List<String> executedJobs = [];

    await FGWorkManager.openQueue(
      queueId: "testQueue",
      process: (job) async {
        executedJobs.add(job.id);
      },
    );

    await FGWorkManager.addJob(
      "testQueue",
      Job(
        id: 'j_1',
        time: DateTime.now().add(Duration(seconds: 1)),
        data: {},
      ),
    );

    await Future.delayed(Duration(seconds: 2));
    expect(executedJobs.contains('j_1'), isTrue);
  });

  test("Should remove a job before execution", () async {
    final List<String> executedJobs = [];

    await FGWorkManager.openQueue(
      queueId: "testQueue2",
      process: (job) async {
        executedJobs.add(job.id);
      },
    );

    await FGWorkManager.addJob(
      "testQueue2",
      Job(
        id: 'j_2',
        time: DateTime.now().add(Duration(seconds: 3)),
        data: {},
      ),
    );

    await Future.delayed(Duration(seconds: 1), () async {
      await FGWorkManager.removeJob(queueId: "testQueue2", jobId: 'j_2');
    });

    await Future.delayed(Duration(seconds: 3));
    expect(executedJobs.contains('j_2'), isFalse);
  });

  test("Should clear the queue", () async {
    await FGWorkManager.openQueue(
      queueId: "testQueue3",
      process: (job) async {},
    );

    await FGWorkManager.addJob(
      "testQueue3",
      Job(
        id: 'j_3',
        time: DateTime.now().add(Duration(seconds: 2)),
        data: {},
      ),
    );

    await FGWorkManager.clearQueue("testQueue3");
    expect(
        () async =>
            await FGWorkManager.removeJob(queueId: "testQueue3", jobId: 'j_3'),
        throwsException);
  });
}
