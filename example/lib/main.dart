import 'package:flutter/material.dart';
import 'package:foreground_work_manager/foreground_work_manager.dart';

void main() async {
  // Initialize the FGWorkManager package.
  // This must be called before using any other functionality.
  await FGWorkManager.init();

  // Open a new job queue with a unique ID and a process callback.
  // The `process` callback defines what happens when a job is executed.
  await FGWorkManager.openQueue(
    queueId: "testQueue",
    process: (job) async {
      // This is where you implement the action for the job.
      // For example, you can print job details or perform a task.
      print(
          "Job: ${job.id} | Current Time: ${DateTime.now().toIso8601String()} | Scheduled Time: ${job.time.toIso8601String()} ");
    },
  );

  // Add a job to the "testQueue".
  // This job is scheduled to run 3 seconds from now.
  FGWorkManager.addJob(
    "testQueue",
    Job(
      id: 'j_1', // Unique ID for the job.
      time:
          DateTime.now().add(Duration(seconds: 3)), // Scheduled execution time.
      data: {}, // Optional data to pass to the job.
    ),
  );

  // Add another job to the "testQueue".
  // This job is also scheduled to run 3 seconds from now.
  FGWorkManager.addJob(
    "testQueue",
    Job(
      id: 'j_2', // Unique ID for the job.
      time:
          DateTime.now().add(Duration(seconds: 3)), // Scheduled execution time.
      data: {}, // Optional data to pass to the job.
    ),
  );

  // Remove the first job (`j_1`) from the queue after 2 seconds.
  // This demonstrates how to cancel a job before it executes.
  Future.delayed(
    Duration(seconds: 2),
    () async {
      await FGWorkManager.removeJob(
        queueId: "testQueue",
        jobId: 'j_1',
      );
    },
  );

  // Clear all jobs from the "testQueue" after 2 minutes.
  // This removes all remaining jobs in the queue.
  Future.delayed(
    Duration(minutes: 2),
    () async {
      await FGWorkManager.clearQueue("testQueue");
    },
  );

  // Remove the entire "testQueue" after 3 minutes.
  // This deletes the queue and all its associated data.
  Future.delayed(
    Duration(minutes: 3),
    () {
      FGWorkManager.removeQueue("testQueue");
    },
  );

  // Run the Flutter app.
  runApp(const MyApp());
}

// The main app widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FGWM Demo', // App title.
      home: MyHomePage(), // Set the home page.
    );
  }
}

// The home page widget.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// The state for the home page.
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "FGWorkManager Demo", // Display a simple text message.
        ),
      ),
    );
  }
}
