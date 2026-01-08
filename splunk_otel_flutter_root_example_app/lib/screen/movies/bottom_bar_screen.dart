import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/favorites_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/home_screen.dart';

class BottomBarScreen extends StatefulWidget {
  final String userEmail;
  const BottomBarScreen({
    required this.userEmail,
    super.key,
  });

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    FavoritesScreen(),
    Text(
      'Empty',
    ),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      // TODO: Implement settings screen
      return;
    }
    if (index == 2 && widget.userEmail == "jan@smartlook.com") {
      exit(2);
    }
    if (index == 1) {
      SplunkOtelFlutter.instance.navigation.track(screenName: 'Favorites Screen');
    }
    if (index == 0) {
      SplunkOtelFlutter.instance.navigation.track(screenName: 'Home Screen');
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_vert),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: ColorPalette.iconSelected,
        unselectedItemColor: ColorPalette.iconNotSelected,
        onTap: _onItemTapped,
      ),
    );
  }
}
