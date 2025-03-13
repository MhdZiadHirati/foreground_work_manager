import 'package:flutter/material.dart';
import 'package:foreground_work_manager/foreground_work_manager.dart';

void main() async {
  await FGWorkManager.init();

  await FGWorkManager.openQueue(
    queueId: "testQueue",
    process: (job) async {
      //implement you action here(job)
      print(
          "job: ${job.id} | time:${DateTime.now().toIso8601String()} | jobTime:${job.time.toIso8601String()} ");
    },
  );

  await FGWorkManager.addJob(
    "testQueue",
    Job(
      id: 'j_1',
      time: DateTime.now().add(Duration(seconds: 3)),
      data: {},
    ),
  );

  await FGWorkManager.addJob(
    "testQueue",
    Job(
      id: 'j_2',
      time: DateTime.now().add(Duration(seconds: 3)),
      data: {},
    ),
  );

  await Future.delayed(
    Duration(seconds: 2),
    () async {
      await FGWorkManager.removeJob(
        queueId: "testQueue",
        jobId: 'j_1',
      );
    },
  );

  await Future.delayed(
    Duration(minutes: 2),
    () async {
      await FGWorkManager.clearQueue("testQueue");
    },
  );

  await FGWorkManager.removeQueue("testQueue");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FGWM Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "FGWorkManager Demo",
        ),
      ),
    );
  }
}
