import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const MyAppBar({super.key, this.actions});

  @override
  State<MyAppBar> createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  String? firmName;

  @override
  void initState() {
    super.initState();
    _loadFirmName();
  }

  Future<void> _loadFirmName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firmName = prefs.getString("firmName") ?? "Firm";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // 👉 Big screens (desktop/tablet): row layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Firm Name
                Text(
                  "Welcome, ${firmName ?? 'Firm'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                // Right side - SIT branding
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.cloud_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'SIT - Swift Cloud : Backup System',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            );
          } else {
            // 👉 Small screens (mobile): stacked column layout
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${firmName ?? 'Firm'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SIT - Swift Cloud : Backup System',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
      actions: widget.actions,
    );
  }
}
