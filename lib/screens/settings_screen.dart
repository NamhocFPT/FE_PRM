import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final String token;
  const SettingsScreen({super.key, required this.token});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  final TextEditingController _incomeController = TextEditingController(
    text: "235555555",
  );
  final TextEditingController _paydayController = TextEditingController(
    text: "15",
  );

  int _income = 235555555;

  List<JarItem> jars = [
    JarItem(
      name: "Nhu cầu thiết yếu",
      icon: Icons.home,
      color: Colors.blue,
      percentage: 55,
    ),
    JarItem(
      name: "Giáo dục",
      icon: Icons.book,
      color: Colors.purple,
      percentage: 10,
    ),
    JarItem(
      name: "Giải trí",
      icon: Icons.sports_esports,
      color: Colors.pink,
      percentage: 10,
    ),
    JarItem(
      name: "Tiết kiệm dài hạn",
      icon: Icons.diamond,
      color: Colors.teal,
      percentage: 10,
    ),
    JarItem(
      name: "Tự do tài chính",
      icon: Icons.flight_takeoff,
      color: Colors.orange,
      percentage: 10,
    ),
    JarItem(
      name: "Cho đi",
      icon: Icons.favorite,
      color: Colors.red,
      percentage: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _incomeController.addListener(() {
      setState(() {
        _income = int.tryParse(_incomeController.text) ?? 0;
      });
    });
  }

  Future<void> _loadSettings() async {
    final userData = await _authService.getUserProfile(widget.token);
    if (!mounted) return;

    if (userData != null) {
      setState(() {
        _incomeController.text =
            userData['monthly_income']?.toString() ?? "235555555";
        _paydayController.text = userData['pay_day']?.toString() ?? "15";
        _income = int.tryParse(_incomeController.text) ?? 235555555;

        if (userData['jars'] != null) {
          Map<String, dynamic> savedJars = userData['jars'];
          for (var jar in jars) {
            if (savedJars.containsKey(jar.name)) {
              jar.percentage = savedJars[jar.name] as int;
              jar.controller.text = jar.percentage.toString();
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _paydayController.dispose();
    for (var jar in jars) {
      jar.controller.dispose();
    }
    super.dispose();
  }

  String formatCurrency(num amount) {
    if (amount == 0) return "0 đ";
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return "${formatter.format(amount)} đ";
  }

  int get totalPercentage {
    return jars.fold(0, (sum, item) => sum + item.percentage);
  }

  Future<void> _saveSettings() async {
    if (totalPercentage != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tổng phân bổ phải đúng bằng 100%")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    Map<String, dynamic> jarsMap = {};
    for (var jar in jars) {
      jarsMap[jar.name] = jar.percentage;
    }

    bool success = await _authService.updateProfile(
      widget.token,
      null, // Tạm thời không cần gửi tên
      monthlyIncome: _incomeController.text.trim(),
      payDay: _paydayController.text.trim(),
      jars: jarsMap,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lưu thay đổi thành công!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không thể lưu cài đặt")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinanceSection(),
              const SizedBox(height: 24),
              _buildJarsSection(),
              const SizedBox(height: 24),
              _buildOtherOptionsSection(),
              const SizedBox(height: 100), // spacing for bottom nav if needed
            ],
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isSaving ? null : _saveSettings,
        child: Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.save, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isSaving ? "Đang lưu..." : "Lưu thay đổi",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Thông tin tài chính",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Thu nhập hàng tháng (VND)",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              suffixIcon: const Icon(Icons.save, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(_income),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            "Ngày nhận lương",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _paydayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJarsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Phân bổ 6 lọ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: totalPercentage == 100
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  "Tổng: $totalPercentage%",
                  style: TextStyle(
                    color: totalPercentage == 100
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                if (totalPercentage == 100)
                  Icon(Icons.check, color: Colors.green.shade700, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...jars.map((jar) => _buildJarItem(jar)),
        ],
      ),
    );
  }

  Widget _buildJarItem(JarItem jar) {
    double value = (_income * jar.percentage) / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: jar.color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(jar.icon, color: jar.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jar.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(value),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: TextField(
                  controller: jar.controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      jar.percentage = int.tryParse(val) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text("%", style: TextStyle(fontSize: 14)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: jar.color,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: jar.color,
                  ),
                  child: Slider(
                    value: jar.percentage.toDouble().clamp(0, 100),
                    min: 0,
                    max: 100,
                    onChanged: (val) {
                      setState(() {
                        jar.percentage = val.toInt();
                        jar.controller.text = jar.percentage.toString();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Tùy chọn khác",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildOptionTile("Ngôn ngữ", "Tiếng Việt"),
          const Divider(height: 1, thickness: 1),
          _buildOptionTile("Giao diện", "Sáng"),
          const Divider(height: 1, thickness: 1),
          _buildOptionTile("Sao lưu dữ liệu", "Tải xuống file JSON"),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class JarItem {
  final String name;
  final IconData icon;
  final Color color;
  int percentage;
  late TextEditingController controller;

  JarItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.percentage,
  }) {
    controller = TextEditingController(text: percentage.toString());
  }
}
