import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/rbac.dart';
import 'access_denied_screen.dart';

class RbacGate extends ConsumerWidget {
  final AppPermission permission;
  final Widget child;

  const RbacGate({
    super.key,
    required this.permission,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final permissionLabel = permissionLabels[permission] ?? permission.name;

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      unauthenticated: () => AccessDeniedScreen(
        message: 'Please sign in to access this page.',
        permissionLabel: permissionLabel,
        showBackButton: false,
      ),
      error: (message) => AccessDeniedScreen(
        message: message,
        permissionLabel: permissionLabel,
      ),
      authenticated: (userName, role, permissions) {
        final allowed = Rbac.canAccess(
          role: role,
          permissions: permissions,
          permission: permission,
        );
        if (allowed) {
          return child;
        }
        return AccessDeniedScreen(
          message: 'You do not have access to this page.',
          permissionLabel: permissionLabel,
        );
      },
    );
  }
}
