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
        // Check if user can access this permission
        final allowed = Rbac.canAccess(
          role: role,
          permissions: permissions,
          permission: permission,
        );

        if (allowed) {
          // User has access - show the page
          return child;
        }

        // Access denied. Show different messages based on role type.
        if (Rbac.isAdmin(role)) {
          // Admin should never be denied, but if it happens, redirect to home
          // This indicates a system issue, not a permission issue.
          return _AdminAccessFallback(
            permissionLabel: permissionLabel,
            userName: userName,
          );
        }

        // Non-admin user denied access - show standard access denied
        return AccessDeniedScreen(
          message: 'You do not have access to this page.',
          permissionLabel: permissionLabel,
        );
      },
    );
  }
}

/// Fallback widget when admin unexpectedly can't access a feature.
/// This should rarely happen (indicates a system issue, not permission issue).
class _AdminAccessFallback extends StatelessWidget {
  final String permissionLabel;
  final String userName;

  const _AdminAccessFallback({
    required this.permissionLabel,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Unavailable'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Feature Not Available',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The "$permissionLabel" feature is not available right now.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
