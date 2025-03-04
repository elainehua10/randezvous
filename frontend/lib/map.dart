import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 1; // Start with index 1 which corresponds to 'Location'

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RandezVous'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.blueAccent,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            'Map Placeholder',
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: ' ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: ' ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: ' ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}