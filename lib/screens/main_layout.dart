import 'package:flutter/material.dart';
import 'projects_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Keeps track of which tab is currently active
  int _selectedIndex = 0;

  // The list of screens that correspond to the tabs
  final List<Widget> _screens = [
    const ProjectsScreen(),
  ];

  // Function to handle tab taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body dynamically changes based on the selected index
      body: _screens[_selectedIndex],

      // The unified bottom navigation bar[cite: 1]
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF334195), // Wireframe Blue
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Study'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_rounded), label: 'Projects'),
        ],
      ),
    );
  }
}