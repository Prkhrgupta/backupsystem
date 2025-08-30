import 'package:flutter/material.dart';

import 'RestorePage.dart';
import 'SchedularPage.dart';
import 'SelectFolderPage.dart';
import 'SideBar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // small helper to change page
  void _onItemSelected(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar fixed width
        SideBar(selectedIndex: _selectedIndex, onItemSelected: _onItemSelected),
        // Main content fills the remaining space
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              SelectFolderPage(),
              SchedulingPage(),
              RestorePage(),
            ],
          ),
        ),
      ],
    );
  }
}
