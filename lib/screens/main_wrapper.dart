import 'package:flutter/material.dart';

import 'income_history_screen.dart';
import 'jars_balances_screen.dart';
import 'profile_screen.dart';
import 'TransactionListScreen.dart';
import 'statistics_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  Key _refreshKey = UniqueKey();

  void _handleProfileUpdated() {
    if (mounted) {
      setState(() {
        // Đổi key để buộc JarsBalancesScreen & StatisticsScreen khởi tạo lại
        _refreshKey = UniqueKey();
      });
    }
  }

  List<Widget> _buildScreens() {
    return [
      JarsBalancesScreen(key: _refreshKey),
      const TransactionListScreen(),
      StatisticsScreen(key: ValueKey('stats_$_refreshKey')),
      ProfileScreen(onProfileUpdated: _handleProfileUpdated),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0E7FF),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

class _StatisticsComingSoonScreen extends StatelessWidget {
  const _StatisticsComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 56, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text(
                'Coming soon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
