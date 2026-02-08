import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bookings/bookings_screen.dart';
import 'reservations/reservations_screen.dart';
import 'profile/settings_screen.dart';
import 'bookings/add_booking_screen.dart';
import 'dashboard/dashboard_screen.dart';
import '../todos/todos_screen.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/rbac.dart';
import '../../shared/widgets/access_denied_screen.dart';

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

    if (availableTabs.isEmpty) {
      return const AccessDeniedScreen(
        message: 'No pages are available for your role.',
        showBackButton: false,
      );
    }

    final safeIndex = _selectedIndex.clamp(0, availableTabs.length - 1);

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
