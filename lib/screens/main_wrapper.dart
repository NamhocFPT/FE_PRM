import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Màn hình Cá nhân bạn đã có

class MainWrapper extends StatefulWidget {
  final String token;
  const MainWrapper({super.key, required this.token});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; // Mặc định vào Trang chủ (index 0)

  // Danh sách các màn hình tương ứng với các tab
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const Scaffold(
        body: Center(child: Text("Trang chủ (Trống)")),
      ), // Index 0: Trang chủ trắng
      const Scaffold(body: Center(child: Text("Lịch sử (Trống)"))), 
      const Scaffold(body: Center(child: Text("Thống kê (Trống)"))), 
      ProfileScreen(token: widget.token), 
    ];
  }

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
//