import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:Zonova_Mist/src/features/home/bookings/bookings_provider.dart'; // Import your booking provider
import 'package:Zonova_Mist/src/features/auth/login_screen.dart'; // Import your login screen

class LogoutTile extends ConsumerWidget {
  const LogoutTile({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // 1. Confirmation Dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // 2. Wipe Storage
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      // 3. Reset Providers (Clean Slate)
      ref.invalidate(authProvider);      // Reset Auth State
      ref.invalidate(bookingsProvider);  // Reset Data
      // ref.invalidate(dashboardProvider); // Reset other providers if needed

      // 4. Force Navigation
      if (context.mounted) {
        // This effectively restarts the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text(
        'Logout',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
      ),
      onTap: () => _handleLogout(context, ref),
    );
  }
}