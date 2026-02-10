import 'package:flutter/foundation.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final String userName;
  final String role;
  final List<String> permissions;
  const Authenticated({
    required this.userName,
    required this.role,
    required this.permissions,
  });
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

enum AuthErrorType { network, expiredToken, invalidToken, storage, unknown }

class AuthError extends AuthState {
  final String message;
  final AuthErrorType type;
  final dynamic cause;

  const AuthError(this.message, {this.type = AuthErrorType.unknown, this.cause});
}

// Using a Freezed-like pattern for convenience
extension AuthStateX on AuthState {
  T when<T>({
    required T Function() loading,
    required T Function(String userName, String role, List<String> permissions) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is AuthLoading) {
      return loading();
    }
    if (this is Authenticated) {
      final auth = this as Authenticated;
      return authenticated(auth.userName, auth.role, auth.permissions);
    }
    if (this is Unauthenticated) {
      return unauthenticated();
    }
    if (this is AuthError) {
      return error((this as AuthError).message);
    }
    throw Exception('Unhandled AuthState: $this');
  }
}

// Optional helpers for callers that want the typed error
extension AuthStateErrorHelpers on AuthState {
  AuthErrorType? get errorType {
    if (this is AuthError) return (this as AuthError).type;
    return null;
  }

  dynamic get errorCause {
    if (this is AuthError) return (this as AuthError).cause;
    return null;
  }
}
