# FGWorkManager

FGWorkManager is a lightweight, easy-to-use foreground job manager for Flutter. Unlike other background job managers, it does not require complex platform-specific configurations. It ensures that jobs are cached and restored even after app restarts, allowing for a seamless job execution process.

## 🚀 Key Benefits
- **No platform-specific setup** – Works out-of-the-box without additional Android/iOS configurations.
- **Jobs persist after app restarts** – Jobs are cached and restored when the app reopens.
- **Two behaviors for past-due jobs after a restart:**
  1. **Execute** – The job runs once the app is opened.
  2. **Ignore** – The job is discarded.

## 📌 Installation
Add FGWorkManager to your `pubspec.yaml`:
```yaml
dependencies:
  foreground_work_manager: latest_version
```

Import the package:
```dart
import 'package:foreground_work_manager/foreground_work_manager.dart';
```

## 📖 Usage Example

```dart
await FGWorkManager.init();

await FGWorkManager.openQueue(
  queueId: "testQueue",
  process: (job) async {
    print("Job: ${job.id} | Executed at: ${DateTime.now().toIso8601String()} | Scheduled at: ${job.time.toIso8601String()}");
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

// Remove a job before execution
await Future.delayed(Duration(seconds: 2), () async {
  await FGWorkManager.removeJob(queueId: "testQueue", jobId: 'j_1');
});

// Clear queue after some time
await Future.delayed(Duration(minutes: 2), () async {
  await FGWorkManager.clearQueue("testQueue");
});

await FGWorkManager.removeQueue("testQueue");
```

## ⚡ How It Works
- Jobs are added to **queues**, which execute tasks at their scheduled time.
- If a job is **not executed before an app restart**, it will follow one of two behaviors:
  - **Execute** – The job runs when the app is reopened.
  - **Ignore** – The job is discarded.
- Jobs are stored in a cache and automatically restored after an app restart.

## 📌 When to Use FGWorkManager?
✅ When you need **task execution while the app is running** (not in the background).  
✅ When you **don’t want to configure platform-specific settings**.  
✅ When you need **persistent job execution across app restarts**.  
✅ When **jobs should execute in order** using a queue system.

## ❓ Need Background Execution?
If you need jobs to run even when the app is **closed**, consider using [Workmanager](https://pub.dev/packages/workmanager), which supports native background execution.

---

### 🎯 Get Started Now!
FGWorkManager is an efficient solution for managing job execution **without complex setups**. Try it today and simplify your Flutter task management!

