import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart'; // FIX: Required for StateNotifier in Riverpod 3.x
import 'package:flutter_riverpod/legacy.dart'; // FIX: StateNotifierProvider moved to legacy in Riverpod 3.x
import 'package:flutter_task_mgmt_app/features/auth/domain/auth_state.dart';
import '../../../../core/network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref); // FIX: Pass ref to enable provider invalidation
});

/// AuthNotifier manages authentication state and token persistence
///
/// Key Features:
/// - Accepts Ref to enable provider invalidation
/// - Saves JWT token to secure storage after successful login
/// - Invalidates authTokenProvider to trigger router redirect
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(AuthInitial());

  final Ref ref; // Required for invalidating providers
  final dio = DioClient().dio;
  final storage = const FlutterSecureStorage();

  /// Performs login and triggers navigation via provider invalidation
  ///
  /// Flow:
  /// 1. Set loading state
  /// 2. Call login API
  /// 3. Save token to secure storage
  /// 4. **Invalidate authTokenProvider** - This forces GoRouter to re-evaluate
  ///    the redirect logic, which reads the fresh token and allows navigation
  /// 5. Set success state (triggers UI listener for context.go('/tasks'))
  Future<void> login(String email, String password) async {
    state = AuthLoading();

    try {
      final response = await dio.post(
        "/login",
        data: {"email": email, "password": password},
      );

      // Save token to secure storage
      await storage.write(key: "token", value: response.data["token"]);

      // FIX: Invalidate authTokenProvider to force router redirect to re-evaluate
      // This is the key fix - without this, the router's FutureProvider won't
      // refresh and will still think the user is unauthenticated
      ref.invalidate(authTokenProvider);

      // Set success state (triggers navigation in LoginScreen listener)
      state = AuthSuccess();
    } catch (e) {
      state = AuthError("Login failed");
    }
  }
}
