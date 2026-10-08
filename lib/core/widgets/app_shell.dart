import 'package:flutter/material.dart';

import '../../features/explore/explore_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/prayer/prayer_screen.dart';
import '../../features/quran/quran_screen.dart';
import '../../l10n/strings.dart';

/// Bottom-navigation shell: Home · Quran · Prayer · Explore · More.
///
/// Quran / Explore / More show honest "coming in Phase 2" states where the
/// feature is not built yet — real navigation, no fake functionality.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onNavigate: _go),
      const QuranScreen(),
      const PrayerScreen(),
      const ExploreScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _go,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: S.of(context, 'nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: S.of(context, 'nav_quran'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.mosque_outlined),
            activeIcon: const Icon(Icons.mosque),
            label: S.of(context, 'nav_prayer'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: S.of(context, 'nav_explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            label: S.of(context, 'nav_more'),
          ),
        ],
      ),
    );
  }
}
