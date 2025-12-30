import 'package:flutter/material.dart';
import 'bookings/bookings_screen.dart';
import 'reservations/reservations_screen.dart';
import 'profile/settings_screen.dart';
import 'bookings/add_booking_screen.dart';
import 'dashboard/dashboard_screen.dart';
import '../todos/todos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  final _pages = const [
    DashboardScreen(),
    BookingsScreen(),
    ReservationsScreen(),
    TodosScreen(), // Full todos screen with both tabs
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Reservations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: "Todos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
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