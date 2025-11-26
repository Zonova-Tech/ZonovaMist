import 'package:flutter/material.dart';
import '../../features/home/staff/staff_screen.dart';
import '../../features/home/rooms/rooms_screen.dart';
import '../../features/todos/todos_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo on the left
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.hotel,
                            size: 40,
                            color: Colors.blue.shade700,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text on the right
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zonova Mist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Guest House\nManagement System',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rooms Menu Item
            ListTile(
              leading: Icon(Icons.meeting_room, color: Colors.blue.shade700),
              title: const Text(
                'Rooms',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Manage rooms',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoomsScreen(showBackButton: true),
                  ),
                );
              },
            ),
            const Divider(height: 1),

            // Staff Menu Item
            ListTile(
              leading: Icon(Icons.people, color: Colors.blue.shade700),
              title: const Text(
                'Guest Staff',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Manage staff members',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),

            // Todos Menu Item
            ListTile(
              leading: Icon(Icons.checklist, color: Colors.blue.shade700),
              title: const Text(
                'Todos',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Manage tasks',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TodosScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),

            // About Menu Item
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey.shade600),
              title: const Text(
                'About',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Zonova Mist',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.hotel,
                          size: 50,
                          color: Colors.blue.shade700,
                        );
                      },
                    ),
                  ),
                  children: const [
                    SizedBox(height: 10),
                    Text('Guest House Management System'),
                    Text('© 2024 Zonova Mist'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}