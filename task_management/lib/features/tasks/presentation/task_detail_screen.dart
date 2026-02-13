import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/task_model.dart';
import '../domain/task_state.dart';
import 'task_notifier.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late String selectedStatus;
  late TextEditingController remarksController;

  @override
  void initState() {
    super.initState();

    // FIX: Validate status to prevent DropdownButton assertion error
    // If backend returns invalid status, default to "pending"
    final validStatuses = ["pending", "completed"];
    selectedStatus = validStatuses.contains(widget.task.status.toLowerCase())
        ? widget.task.status.toLowerCase()
        : "pending";

    remarksController = TextEditingController(text: widget.task.remarks);
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX #1: Get fresh task from provider state instead of using stale widget.task
    final taskState = ref.watch(taskProvider);

    // Find the current task from provider state
    TaskModel? currentTask;
    if (taskState is TaskLoaded) {
      currentTask = taskState.tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => widget.task,
      );
    } else {
      currentTask = widget.task;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Detail"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tasks'), // FIX #2: Explicit navigation
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              currentTask.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // FIX #1: Description from fresh provider state
            if (currentTask.description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  currentTask.description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "completed", child: Text("Completed")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),

            const SizedBox(height: 20),

            // Remarks Field
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: "Remarks",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Add your remarks here...',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            // Sync Status Indicator
            if (!currentTask.isSynced)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This task has pending changes that will sync when online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!currentTask.isSynced) const SizedBox(height: 24),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Update task
                  await ref
                      .read(taskProvider.notifier)
                      .updateTask(
                        widget.task,
                        status: selectedStatus,
                        remarks: remarksController.text,
                      );

                  // FIX #2: CRITICAL - Use context.go() instead of pop()
                  // This prevents app exit and ensures correct navigation stack
                  if (context.mounted) {
                    context.go('/tasks');
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text(
                  "Update Task",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
