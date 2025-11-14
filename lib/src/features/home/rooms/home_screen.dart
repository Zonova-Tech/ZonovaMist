import 'package:flutter/material.dart';
import '../bookings/bookings_screen.dart';
import 'rooms_screen.dart';
import '../reservations/reservations_screen.dart';
import '../hotels/partner_hotels_screen.dart';
import '../profile/settings_screen.dart';
import '../bookings/add_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    BookingsScreen(),
    ReservationsScreen(),
    PartnerHotelsScreen(),
    RoomsScreen(),
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
        selectedItemColor: Theme.of(context).primaryColor, // ✅ theme color
        unselectedItemColor: Colors.grey, // ✅ dimmed icons for inactive
        showUnselectedLabels: true, // optional: show labels for all
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Reservations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel),
            label: "Hotels",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: "Rooms",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
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
