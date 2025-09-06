import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SideBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildTile(context, 0, 'Select Folder', Icons.folder),
          _buildTile(context, 1, 'Scheduling', Icons.schedule),
          _buildTile(context, 2, 'Restore', Icons.restore),
        ],
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, int idx, String title, IconData icon) {
    final bool selected = idx == selectedIndex;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: () => onItemSelected(idx),
    );
  }
}
