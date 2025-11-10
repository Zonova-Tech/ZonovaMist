import 'package:flutter/material.dart';
import '../../features/home/staff/staff_screen.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
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
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    'Zonova Mist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    'Guest House Management',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Staff Menu Item
            ListTile(
              leading: Icon(Icons.people, color: Colors.blue.shade700),
              title: Text(
                'Guest Staff',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Manage staff members',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffScreen(),
                  ),
                );
              },
            ),
            Divider(height: 1),
            // About Menu Item
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey.shade600),
              title: Text(
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
                  children: [
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