import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root tab scaffold (HOME / SETTINGS).
///
/// Hosts the bottom navigation bar and renders the active branch of the
/// [`StatefulShellRoute.indexedStack`] declared in `app_router.dart`.
///
/// Tabs are switched via [`StatefulNavigationShell.goBranch`], so selecting a
/// tab swaps branches in place instead of pushing a new route onto the stack
/// (unlike `context.push`, which would pile screens on top of each other and
/// leave the nav bar behind).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
