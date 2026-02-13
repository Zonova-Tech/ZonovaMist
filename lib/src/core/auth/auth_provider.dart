import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';
import 'package:Zonova_Mist/src/core/auth/auth_constants.dart';
import 'package:Zonova_Mist/src/core/auth/auth_utils.dart';


final tokenProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthLoading()) {
    _checkToken();
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _checkToken() async {
    try {
      final token = await _storage.read(key: AuthConstants.jwtKey);
      if (token != null) {
        // Treat malformed/expired tokens as absent
        if (isJwtExpired(token)) {
          await _storage.delete(key: AuthConstants.jwtKey);
          state = const Unauthenticated();
          return;
        }

        // 2. LOAD TOKEN INTO RAM ON APP START
        _ref.read(tokenProvider.notifier).state = token;

        final userFullName = await _storage.read(key: AuthConstants.userFullNameKey);
        final role = await _storage.read(key: AuthConstants.userRoleKey) ?? safeGetRoleFromPayload(token) ?? 'Guest';
        final permissionsRaw = await _storage.read(key: AuthConstants.userPermissionsKey);
        final permissions = _decodePermissions(permissionsRaw);
        state = Authenticated(
          userName: userFullName ?? 'User',
          role: role,
          permissions: permissions,
        );
      } else {
        state = const Unauthenticated();
      }
    } catch (e, st) {
      // Storage/read error -> mark as error but fall back to unauthenticated
      state = AuthError('Failed to read authentication data', type: AuthErrorType.storage, cause: e);
      Future.delayed(const Duration(seconds: 1), () => state = const Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final response = await _ref.read(dioProvider).post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final token = response.data['token'] as String?;
      final userFullName = response.data['user']?['fullName'] ?? response.data['userFullName'] ?? 'User';
      final role = response.data['user']?['role'] ?? response.data['role'] ?? 'Guest';
      final permissions = _extractPermissions(response.data);

      if (token == null) {
        state = const AuthError('Authentication token missing from response', type: AuthErrorType.unknown);
        Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
        return;
      }

      // Check token expiry
      if (isJwtExpired(token)) {
        state = const AuthError('Received expired token', type: AuthErrorType.expiredToken);
        Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
        return;
      }

      // Write to Disk (Slow, Persistent)
      await _storage.write(key: AuthConstants.jwtKey, value: token);
      await _storage.write(key: AuthConstants.userFullNameKey, value: userFullName);
      await _storage.write(key: AuthConstants.userRoleKey, value: role.toString());
      await _storage.write(key: AuthConstants.userPermissionsKey, value: jsonEncode(permissions));

      // 3. UPDATE RAM IMMEDIATELY (Fast, for immediate API calls)
      _ref.read(tokenProvider.notifier).state = token;

      state = Authenticated(
        userName: userFullName,
        role: role.toString(),
        permissions: permissions,
      );
    } on DioException catch (e) {
      final message = e.response?.data != null
          ? (e.response!.data is Map ? (e.response!.data['message'] ?? 'An unknown error occurred') : e.response!.data.toString())
          : e.message ?? 'Network error';
      state = AuthError(message, type: AuthErrorType.network, cause: e);
      Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
    } catch (e) {
      state = AuthError('An unexpected error occurred', type: AuthErrorType.unknown, cause: e);
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
      state = AuthError(message, type: AuthErrorType.network, cause: e);
      Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
      return message;
    } catch (e) {
      state = AuthError('An unexpected error occurred', type: AuthErrorType.unknown, cause: e);
      Future.delayed(const Duration(seconds: 2), () => state = const Unauthenticated());
      return 'An unexpected error occurred';
    }
  }

  Future<void> logout() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // ignore storage delete errors, still clear RAM
    }

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
    try {
      final permissions = data['permissions'] ?? data['user']?['permissions'];
      if (permissions is List) {
        return permissions.map((permission) => permission.toString()).toList();
      }
    } catch (_) {}
    return <String>[];
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
