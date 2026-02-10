import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bookings/bookings_screen.dart';
import 'reservations/reservations_screen.dart';
import 'profile/settings_screen.dart';
import 'bookings/add_booking_screen.dart';
import 'dashboard/dashboard_screen.dart';
import '../todos/todos_screen.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/rbac.dart';
import '../../shared/widgets/access_denied_screen.dart';
import 'dart:developer' as developer;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 1;

  List<_HomeTab> _buildTabs(String role, List<String> permissions) {
    final allTabs = [
      const _HomeTab(
        permission: AppPermission.dashboard,
        label: 'Dashboard',
        icon: Icons.dashboard,
        page: DashboardScreen(),
      ),
      const _HomeTab(
        permission: AppPermission.bookings,
        label: 'Bookings',
        icon: Icons.book_online,
        page: BookingsScreen(),
      ),
      const _HomeTab(
        permission: AppPermission.reservations,
        label: 'Reservations',
        icon: Icons.calendar_today,
        page: ReservationsScreen(),
      ),
      const _HomeTab(
        permission: AppPermission.todos,
        label: 'Todos',
        icon: Icons.checklist,
        page: TodosScreen(),
      ),
      const _HomeTab(
        permission: AppPermission.settings,
        label: 'Settings',
        icon: Icons.settings,
        page: SettingsScreen(),
      ),
    ];

    // Filter tabs based on role and permissions
    return allTabs
        .where(
          (tab) => Rbac.canAccess(
            role: role,
            permissions: permissions,
            permission: tab.permission,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final availableTabs = authState.when(
      loading: () => <_HomeTab>[],
      unauthenticated: () => <_HomeTab>[],
      error: (_) => <_HomeTab>[],
      authenticated: (_, role, permissions) => _buildTabs(role, permissions),
    );

    // Extract role for debug logging
    String userRole = 'unknown';
    if (authState is Authenticated) {
      final auth = authState;
      userRole = auth.role;
    }

    // Debug logging: show role and number of visible tabs
    developer.log(
      'HomeScreen build - Role: $userRole, Available tabs: ${availableTabs.length}',
      name: 'HomeScreen',
    );

    if (availableTabs.isEmpty) {
      // Check if user is admin - they should always have access to dashboard
      if (authState is Authenticated) {
        final auth = authState;
        if (Rbac.isAdmin(auth.role)) {
          developer.log(
            'Admin with no tabs - showing fallback dashboard',
            name: 'HomeScreen',
          );
          // Admin has no tabs available - this is a system issue, not a permission issue.
          // Show a fallback dashboard or redirect to home.
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dashboard,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No dashboard features available at the moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // Non-admin user has no available pages
      return const AccessDeniedScreen(
        message: 'No pages are available for your role.',
        showBackButton: false,
      );
    }

    final safeIndex = _selectedIndex.clamp(0, availableTabs.length - 1);

    // BottomNavigationBar requires minimum 2 items (Flutter assertion).
    // If user has fewer than 2 tabs, render without bottom navigation bar.
    // This typically occurs for 'staff' and 'user' roles with minimal permissions.
    final hasMultipleTabs = availableTabs.length >= 2;

    if (!hasMultipleTabs) {
      developer.log(
        'Single tab only (${availableTabs.length}) - rendering without BottomNavigationBar. '
        'This is normal for roles like "staff" and "user" with minimal permissions.',
        name: 'HomeScreen',
      );

      // Single-tab fallback: render without bottom navigation
      return Scaffold(
        body: availableTabs[safeIndex].page,
        floatingActionButton: availableTabs[safeIndex].permission == AppPermission.bookings
            ? FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBookingScreen()),
            );
          },
          child: const Icon(Icons.add),
        )
            : null,
      );
    }

    // Multi-tab layout: render with BottomNavigationBar
    developer.log(
      'Rendering BottomNavigationBar with ${availableTabs.length} tabs',
      name: 'HomeScreen',
    );

    return Scaffold(
      body: availableTabs[safeIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          for (final tab in availableTabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
        ],
      ),
      floatingActionButton: availableTabs[safeIndex].permission == AppPermission.bookings
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookingScreen()),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class _HomeTab {
  final AppPermission permission;
  final String label;
  final IconData icon;
  final Widget page;

  const _HomeTab({
    required this.permission,
    required this.label,
    required this.icon,
    required this.page,
  });
}
