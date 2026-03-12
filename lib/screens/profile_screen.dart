import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';
import 'monthly_report_screen.dart';
import 'savings_goal_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String name = "Đang tải...";
  String email = "";
  String monthlyIncome = "";
  String payDay = "";
  String currency = "VND";
  bool isLoading = true;

  final Map<String, Map<String, String>> labels = {
    'profile_title': {'VND': 'Cá nhân', 'USD': 'Profile'},
    'loading': {'VND': 'Đang tải...', 'USD': 'Loading...'},
    'load_error': {
      'VND': 'Không thể tải thông tin cá nhân',
      'USD': 'Unable to load profile',
    },
    'monthly_income': {
      'VND': 'Thu nhập hàng tháng',
      'USD': 'Monthly Income',
    },
    'salary_day': {'VND': 'Ngày nhận lương', 'USD': 'Salary Payment Day'},
    'not_set': {'VND': 'Chưa thiết lập', 'USD': 'Not set'},
    'salary_day_prefix': {'VND': 'Ngày ', 'USD': 'Day '},
    'edit_name_title': {'VND': 'Đổi tên hiển thị', 'USD': 'Change Display Name'},
    'name_hint': {
      'VND': 'Nhập tên mới của bạn',
      'USD': 'Enter your new name',
    },
    'full_name_label': {'VND': 'Họ và tên', 'USD': 'Full Name'},
    'cancel': {'VND': 'Hủy', 'USD': 'Cancel'},
    'save': {'VND': 'Lưu', 'USD': 'Save'},
    'update_success': {
      'VND': 'Cập nhật hồ sơ thành công!',
      'USD': 'Profile updated successfully!',
    },
    'update_error': {
      'VND': 'Lỗi: Không thể cập nhật tên',
      'USD': 'Error: Unable to update name',
    },
    'financial_info': {
      'VND': 'Thông tin tài chính',
      'USD': 'Financial Information',
    },
    'edit_name': {'VND': 'Đổi tên hiển thị', 'USD': 'Change Display Name'},
    'settings': {'VND': 'Cài đặt tài khoản', 'USD': 'Account Settings'},
    'notifications': {'VND': 'Thông báo', 'USD': 'Notifications'},
    'monthly_report': {'VND': 'Báo cáo tháng', 'USD': 'Monthly Report'},
    'savings_goal': {'VND': 'Mục tiêu tiết kiệm', 'USD': 'Savings Goals'},
    'logout': {'VND': 'ĐĂNG XUẤT', 'USD': 'LOGOUT'},
    'transactions': {'VND': 'Giao dịch', 'USD': 'Transactions'},
    'goals_reached': {'VND': 'Mục tiêu đạt', 'USD': 'Goals Reached'},
  };

  String _getLabel(String key) {
    return labels[key]?[currency] ?? labels[key]?['VND'] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userData = await _authService.getUserProfile();
      if (!mounted) return;

      if (userData != null) {
        setState(() {
          name = userData['full_name'] ?? "User";
          email = userData['email'] ?? "";
          monthlyIncome = userData['monthly_income']?.toString() ?? "";
          payDay = userData['pay_day']?.toString() ?? "";
          currency = userData['currency'] ?? "VND";
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getLabel('load_error'))),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('load_error'))),
      );
    }
  }

  String _formatIncome() {
    if (monthlyIncome.isEmpty) return _getLabel('not_set');
    return currency == 'USD' ? '\$$monthlyIncome' : '₫$monthlyIncome';
  }

  void _updateName() {
    final TextEditingController nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_getLabel('edit_name_title')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _getLabel('name_hint'),
            labelText: _getLabel('full_name_label'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              _getLabel('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(dialogContext);

              if (newName == name) return;

              final success = await _authService.updateProfile(newName);

              if (!mounted) return;

              if (success) {
                await _loadProfile();
                widget.onProfileUpdated?.call();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getLabel('update_success'))),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getLabel('update_error'))),
                );
              }
            },
            child: Text(_getLabel('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getLabel('profile_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 45,
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeaderStat('0', _getLabel('transactions')),
                            const SizedBox(width: 10),
                            _buildHeaderStat('0', _getLabel('goals_reached')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLabel('financial_info'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFinanceItem(
                          icon: Icons.attach_money,
                          label: _getLabel('monthly_income'),
                          value: _formatIncome(),
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildFinanceItem(
                          icon: Icons.calendar_today_outlined,
                          label: _getLabel('salary_day'),
                          value: payDay.isEmpty
                              ? _getLabel('not_set')
                              : "${_getLabel('salary_day_prefix')}$payDay",
                        ),
                      ],
                    ),
                  ),

                  _buildMenuTile(
                    icon: Icons.edit_note,
                    title: _getLabel('edit_name'),
                    onTap: _updateName,
                  ),
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: _getLabel('settings'),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      if (!mounted) return;
                      await _loadProfile();
                      widget.onProfileUpdated?.call();
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.notifications_none,
                    title: _getLabel('notifications'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.bar_chart_rounded,
                    title: _getLabel('monthly_report'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MonthlyReportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.savings_outlined,
                    title: _getLabel('savings_goal'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavingsGoalScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await _authService.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        _getLabel('logout'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '6 Chiếc Lọ v1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(
                    '© 2026 Figma Make Demo',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFinanceItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6366F1)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}