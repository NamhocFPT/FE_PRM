import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'TransactionListScreen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  String _currency = 'VND';
  bool _isLoading = true;

  late List<Widget> _screens;

  final navLabels = {
    'VND': {
      'home': 'Trang chủ',
      'history': 'Lịch sử',
      'stats': 'Thống kê',
      'profile': 'Cá nhân',
    },
    'USD': {
      'home': 'Home',
      'history': 'History',
      'stats': 'Statistics',
      'profile': 'Profile',
    }
  };

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    final authService = AuthService();
    final userData = await authService.getUserProfile();
    if (mounted) {
      setState(() {
        final rawCurrency = (userData?['currency'] ?? 'VND').toString().toUpperCase();
        _currency = rawCurrency.isEmpty ? 'VND' : rawCurrency;
        _screens = [
          const Scaffold(
            body: Center(child: Text("Coming Soon")),
          ),
          const TransactionListScreen(),
          const Scaffold(
            body: Center(child: Text("Coming Soon")),
          ),
          ProfileScreen(onProfileUpdated: _loadUserCurrency),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navLabel = navLabels[_currency];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: navLabel?['home'] ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: navLabel?['history'] ?? 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart_outline),
            label: navLabel?['stats'] ?? 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: navLabel?['profile'] ?? 'Profile',
          ),
        ],
      ),
    );
  }
}