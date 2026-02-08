import 'dart:convert';

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
      final role = await _storage.read(key: 'user_role') ?? 'Guest';
      final permissionsRaw = await _storage.read(key: 'user_permissions');
      final permissions = _decodePermissions(permissionsRaw);
      state = Authenticated(
        userName: userFullName ?? 'User',
        role: role,
        permissions: permissions,
      );
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
      final role = response.data['user']['role'] ?? response.data['role'] ?? 'Guest';
      final permissions = _extractPermissions(response.data);

      // Write to Disk (Slow, Persistent)
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_full_name', value: userFullName);
      await _storage.write(key: 'user_role', value: role.toString());
      await _storage.write(key: 'user_permissions', value: jsonEncode(permissions));

      // 3. UPDATE RAM IMMEDIATELY (Fast, for immediate API calls)
      _ref.read(tokenProvider.notifier).state = token;

      state = Authenticated(
        userName: userFullName,
        role: role.toString(),
        permissions: permissions,
      );
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

  List<String> _decodePermissions(String? permissionsRaw) {
    if (permissionsRaw == null || permissionsRaw.isEmpty) {
      return <String>[];
    }
    try {
      final decoded = jsonDecode(permissionsRaw);
      if (decoded is List) {
        return decoded.map((permission) => permission.toString()).toList();
      }
    } catch (_) {}
    return <String>[];
  }

  List<String> _extractPermissions(Map<String, dynamic> data) {
    final permissions = data['permissions'] ?? data['user']?['permissions'];
    if (permissions is List) {
      return permissions.map((permission) => permission.toString()).toList();
    }
    return <String>[];
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
