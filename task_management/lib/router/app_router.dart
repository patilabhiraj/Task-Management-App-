import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_mgmt_app/features/tasks/domain/task_model.dart';
import 'package:flutter_task_mgmt_app/features/tasks/presentation/task_detail_screen.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/tasks/presentation/task_list_screen.dart';
import '../core/services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authTokenProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) {
          final task = state.extra as TaskModel;
          return TaskDetailScreen(task: task);
        },
      ),
    ],
    redirect: (context, state) {
      final token = authState.value;

      final isLoggingIn = state.uri.path == '/login';

      if (token == null && !isLoggingIn) {
        return '/login';
      }

      if (token != null && isLoggingIn) {
        return '/tasks';
      }

      return null;
    },
  );
});
