import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String name = "Đang tải...";
  String email = "";
  String monthlyIncome = "";
  String payDay = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userData = await _authService.getUserProfile(widget.token);
    if (!mounted) return;

    if (userData != null) {
      setState(() {
        name = userData['full_name'] ?? "Người dùng";
        email = userData['email'] ?? "";
        monthlyIncome = userData['monthly_income']?.toString() ?? "";
        payDay = userData['pay_day']?.toString() ?? "";
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể tải thông tin cá nhân")),
      );
    }
  }

  void _updateName() {
    final TextEditingController nameController = TextEditingController(
      text: name,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Đổi tên hiển thị"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Nhập tên mới của bạn",
            labelText: "Họ và tên",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameController.text.trim();

              if (newName.isEmpty) {
                return;
              }

              Navigator.pop(dialogContext); // Đóng dialog ngay sau khi nhấn Lưu

              // Nếu tên không đổi, không gọi API nhưng có thể báo thành công ảo để UX mượt
              if (newName == name) {
                return;
              }

              bool success = await _authService.updateProfile(
                widget.token,
                newName,
              );

              if (!mounted) return;

              if (success) {
                await _loadProfile(); // Tải lại toàn bộ hồ sơ từ server
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cập nhật hồ sơ thành công!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lỗi: Không thể cập nhật tên")),
                );
              }
            },
            child: const Text("Lưu"),
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
                        const Text(
                          'Cá nhân',
                          style: TextStyle(
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
                            _buildHeaderStat('0', 'Giao dịch'),
                            const SizedBox(width: 10),
                            _buildHeaderStat('0', 'Mục tiêu đạt'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- THÔNG TIN TÀI CHÍNH (Dữ liệu động) ---
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài chính',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFinanceItem(
                          icon: Icons.attach_money,
                          label: 'Thu nhập hàng tháng',
                          value: monthlyIncome.isEmpty
                              ? "Chưa thiết lập"
                              : "$monthlyIncome đ",
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildFinanceItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày nhận lương',
                          value: payDay.isEmpty
                              ? "Chưa thiết lập"
                              : "Ngày $payDay",
                        ),
                      ],
                    ),
                  ),

                  // --- MENU ---
                  _buildMenuTile(
                    icon: Icons.edit_note,
                    title: "Đổi tên hiển thị",
                    onTap: _updateName,
                  ),
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: "Cài đặt tài khoản",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(token: widget.token),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.notifications_none,
                    title: "Thông báo",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
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
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "ĐĂNG XUẤT",
                        style: TextStyle(
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
        color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.black.withValues(alpha: 0.05),
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
//