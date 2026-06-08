import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/stats/views/stats_screen.dart';
import '../../features/tournaments/views/tournaments_screen.dart';
import '../../features/teams/views/teams_screen.dart';
import '../../features/rankings/views/rankings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StatsScreen(),
    TournamentsScreen(),
    TeamsScreen(),
    RankingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.black,
          border: Border(top: BorderSide(color: AppColors.primaryYellow, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.black,
          selectedItemColor: AppColors.primaryYellow,
          unselectedItemColor: AppColors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_cricket),
              label: 'MATCHES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'TOURNAMENTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'TEAMS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'RANKINGS',
            ),
          ],
        ),
      ),
    );
  }
}
