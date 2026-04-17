import 'package:flutter/material.dart';

class NavigationWidget extends StatefulWidget {
  NavigationWidget({super.key});
  int _selectedIndex = 0;
  final bool _isSwiping = false;

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Selected Index: ${widget._selectedIndex}'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget._selectedIndex,
        onTap: (index) {
          setState(() {
            widget._selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}