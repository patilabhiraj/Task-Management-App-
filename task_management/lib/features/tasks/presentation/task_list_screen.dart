import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../domain/task_state.dart';
import 'task_notifier.dart';
import 'package:go_router/go_router.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _hasLoadedTasks = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();

    if (!_hasLoadedTasks) {
      _hasLoadedTasks = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(taskProvider.notifier).fetchTasksFromApi().then((_) {
          if (mounted) {
            setState(() {
              _isInitialLoad = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: state is TaskLoading
              ? const LinearProgressIndicator()
              : const SizedBox(height: 4.0),
        ),
        actions: [
          // Last Synced Indicator
          _LastSyncedWidget(),
          // Manual Refresh Button
          IconButton(
            onPressed: () {
              ref.read(taskProvider.notifier).fetchTasksFromApi();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from server',
          ),
        ],
      ),
      body: RefreshIndicator(
        // Pull-to-refresh gesture
        onRefresh: () => ref.read(taskProvider.notifier).fetchTasksFromApi(),
        child: _isInitialLoad
            ? _buildLoadingState() // Show skeleton loader on first load
            : switch (state) {
                TaskLoading() => _buildLoadingState(),
                TaskLoaded(:final tasks) =>
                  tasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _TaskCard(task: task);
                          },
                        ),
                TaskError(:final message) => _buildErrorState(
                  context,
                  ref,
                  message,
                ),
                _ => _buildLoadingState(), // Show loading for initial state
              },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const _SkeletonTaskCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Sync Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(taskProvider.notifier).fetchTasksFromApi();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////// Displays last synced time
class _LastSyncedWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaBox = Hive.box('metaBox');
    final lastSyncedStr = metaBox.get("lastSynced") as String?;

    if (lastSyncedStr == null) {
      return const SizedBox();
    }

    try {
      final lastSynced = DateTime.parse(lastSyncedStr);
      final now = DateTime.now();
      final diff = now.difference(lastSynced);

      String timeAgo;
      if (diff.inSeconds < 60) {
        timeAgo = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }

      return Padding(padding: const EdgeInsets.only(right: 8));
    } catch (e) {
      return const SizedBox();
    }
  }
}

/// Enhanced Task Card with sync status and timestamp
class _TaskCard extends StatelessWidget {
  final dynamic task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: InkWell(
        onTap: () {
          context.go('/task/${task.id}', extra: task);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Title + Sync Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(
                      task.status,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(task.status),
                      color: _getStatusColor(task.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              task.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(task.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sync Status Icon
                  task.isSynced
                      ? Icon(
                          Icons.cloud_done,
                          color: Colors.green[600],
                          size: 20,
                        )
                      : Icon(
                          Icons.cloud_upload,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                ],
              ),

              // Remarks (if any)
              if (task.remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.remarks,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Bottom Row: Timestamp (FIX #3: Bottom-right position)
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _getTimeAgo(task.updatedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.pending;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.task;
    }
  }
}

/// Skeleton loader for loading state
class _SkeletonTaskCard extends StatelessWidget {
  const _SkeletonTaskCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: Colors.grey[300]),
        title: Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          height: 12,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Icon(Icons.cloud_outlined, color: Colors.grey[300]),
      ),
    );
  }
}
