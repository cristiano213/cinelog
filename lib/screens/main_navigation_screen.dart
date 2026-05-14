import 'package:flutter/material.dart';
import 'stats_screen.dart';
import 'discovery_screen.dart';
// Importa qui la futura StatsScreen (per ora mettiamo un placeholder)
// import 'stats_screen.dart'; 

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Lista delle schermate principali
  final List<Widget> _screens = [
    const DiscoveryScreen(),
    const StatsScreen(), // <--- Ecco la vera Dashboard!
    const Center(child: Text('Social & Cinema (Coming Soon)', style: TextStyle(color: Colors.white))),
  ];  

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Mantiene le label visibili
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie_filter), label: 'Film'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Social'),
        ],
      ),
    );
  }
}