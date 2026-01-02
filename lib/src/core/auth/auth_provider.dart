import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';


final tokenProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthLoading()) {
    _checkToken();
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      // 2. LOAD TOKEN INTO RAM ON APP START
      _ref.read(tokenProvider.notifier).state = token;
      
      final userFullName = await _storage.read(key: 'user_full_name');
      state = Authenticated(userFullName ?? 'User');
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      print("before call");
      final response = await _ref.read(dioProvider).post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      print("after call");
      final token = response.data['token'];
      final userFullName = response.data['user']['fullName'];

      // Write to Disk (Slow, Persistent)
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_full_name', value: userFullName);

      // 3. UPDATE RAM IMMEDIATELY (Fast, for immediate API calls)
      _ref.read(tokenProvider.notifier).state = token;

      state = Authenticated(userFullName);
    } on DioException catch (e) {
      print("exception $e");
      final message = e.response?.data['message'] ?? 'An unknown error occurred';
      state = AuthError(message);
      Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
    }
  }

  Future<String> register({required String fullName, required String email, required String password}) async {

    state = const AuthLoading();
    try {
      await _ref.read(dioProvider).post(
        '/auth/register',
        data: {'fullName': fullName, 'email': email, 'password': password},
      );
      state = const Unauthenticated();
      return 'Success';
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'An unknown error occurred';
      state = AuthError(message);
      Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
      return message;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    
    // 4. CLEAR RAM ON LOGOUT
    _ref.read(tokenProvider.notifier).state = null;
    
    state = const Unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});