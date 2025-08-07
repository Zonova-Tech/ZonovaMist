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
  const Authenticated(this.userName);
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Using a Freezed-like pattern for convenience
extension AuthStateX on AuthState {
  T when<T>({
    required T Function() loading,
    required T Function(String userName) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is AuthLoading) {
      return loading();
    }
    if (this is Authenticated) {
      return authenticated((this as Authenticated).userName);
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