import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/jarprofile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final JarProfileService _jarProfileService = JarProfileService();

  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _payDayController = TextEditingController();
  final List<TextEditingController> _percentControllers = [];

  String _currency = 'VND';
  String? _profileId;
  List<Map<String, dynamic>> _jars = [];

  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, Map<String, String>> labels = {
    'title': {'VND': 'Cài đặt', 'USD': 'Settings'},
    'financial': {'VND': 'Thông tin tài chính', 'USD': 'Financial Information'},
    'monthly_income': {'VND': 'Thu nhập hàng tháng', 'USD': 'Monthly Income'},
    'monthly_income_hint': {
      'VND': 'Nhập thu nhập hàng tháng',
      'USD': 'Enter monthly income'
    },
    'salary_day': {'VND': 'Ngày nhận lương', 'USD': 'Salary Payment Day'},
    'salary_day_hint': {
      'VND': 'Ngày trong tháng (1-31)',
      'USD': 'Day of month (1-31)'
    },
    'allocation': {'VND': 'Phân bổ 6 lọ', 'USD': '6 Jars Allocation'},
    'total': {'VND': 'Tổng', 'USD': 'Total'},
    'total_ok': {'VND': 'Đạt 100%', 'USD': '100% OK'},
    'total_error': {
      'VND': 'Tổng phải bằng 100%',
      'USD': 'Total must be 100%'
    },
    'save': {'VND': 'Lưu thay đổi', 'USD': 'Save Changes'},
    'saving': {'VND': 'Đang lưu...', 'USD': 'Saving...'},
    'language': {'VND': 'Ngôn ngữ', 'USD': 'Language'},
    'vietnamese': {'VND': 'Tiếng Việt', 'USD': 'Vietnamese'},
    'english': {'VND': 'Tiếng Anh', 'USD': 'English'},
    'theme': {'VND': 'Giao diện', 'USD': 'Theme'},
    'theme_light': {'VND': 'Sáng', 'USD': 'Light'},
    'coming_soon': {'VND': 'Sẽ cập nhật sau', 'USD': 'Coming soon'},
    'update_success': {
      'VND': 'Cập nhật thành công',
      'USD': 'Update successful'
    },
    'update_error': {'VND': 'Cập nhật thất bại', 'USD': 'Update failed'},
    'invalid_income': {
      'VND': 'Thu nhập phải lớn hơn 0',
      'USD': 'Income must be greater than 0'
    },
    'invalid_day': {
      'VND': 'Ngày nhận lương từ 1-31',
      'USD': 'Salary day must be 1-31'
    },
    'no_profile': {
      'VND': 'Chưa có hồ sơ đang hoạt động',
      'USD': 'No active profile'
    },
  };

  final Map<String, String> jarNameMap = {
    'Nhu cầu thiết yếu': 'Necessities',
    'Giáo dục': 'Education',
    'Giải trí': 'Play',
    'Tiết kiệm dài hạn': 'Long-term Savings',
    'Tự do tài chính': 'Financial Freedom',
    'Cho đi': 'Give',
  };

  String _getLabel(String key) {
    return labels[key]?[_currency] ?? labels[key]?['VND'] ?? '';
  }

  String _jarDisplayName(String? name) {
    if (name == null) return '-';
    if (_currency == 'USD') {
      return jarNameMap[name] ?? name;
    }
    return name;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _payDayController.dispose();
    for (final controller in _percentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final userProfile = await _authService.getUserProfile();
    final activeProfile = await _jarProfileService.getActiveProfile();

    if (!mounted) return;

    if (userProfile != null) {
      _currency = (userProfile['currency'] ?? 'VND').toString();
      _incomeController.text =
          userProfile['monthly_income']?.toString() ?? '';
      _payDayController.text = userProfile['pay_day']?.toString() ?? '';
    }

    if (activeProfile != null) {
      _profileId = activeProfile['_id']?.toString();
      final jars = activeProfile['jars'];
      if (jars is List) {
        _jars = List<Map<String, dynamic>>.from(jars);
      }
    }

    _initPercentControllers();

    setState(() => _isLoading = false);
  }

  void _initPercentControllers() {
    for (final controller in _percentControllers) {
      controller.dispose();
    }
    _percentControllers.clear();

    for (final jar in _jars) {
      final percent = jar['percent']?.toString() ?? '0';
      _percentControllers.add(TextEditingController(text: percent));
    }
  }

  int _totalPercent() {
    int total = 0;
    for (final jar in _jars) {
      final value = jar['percent'];
      if (value is num) {
        total += value.round();
      } else if (value is String) {
        total += int.tryParse(value) ?? 0;
      }
    }
    return total;
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    final sanitized = hex.replaceAll('#', '');
    if (sanitized.length == 6) {
      return Color(int.parse('FF$sanitized', radix: 16));
    }
    return const Color(0xFF6366F1);
  }

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'savings':
        return Icons.savings;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight_takeoff;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Future<void> _updateCurrency(String currency) async {
    if (currency == _currency) return;

    final success = await _authService.updateCurrency(currency);
    if (!mounted) return;

    if (success) {
      setState(() => _currency = currency);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('update_success'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('update_error'))),
      );
    }
  }

  Future<void> _saveSettings() async {
    final total = _totalPercent();
    if (total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('total_error'))),
      );
      return;
    }

    final monthlyIncome = _parseInt(_incomeController.text);
    if (monthlyIncome != null && monthlyIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('invalid_income'))),
      );
      return;
    }

    final payDay = _parseInt(_payDayController.text);
    if (payDay != null && (payDay < 1 || payDay > 31)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('invalid_day'))),
      );
      return;
    }

    if (_profileId == null && _jars.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('no_profile'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    final financeUpdated =
        await _authService.updateFinancialInfo(monthlyIncome, payDay);

    bool jarsUpdated = true;
    if (_profileId != null && _jars.isNotEmpty) {
      jarsUpdated =
          await _jarProfileService.updateJarPercentages(_profileId!, _jars);
    }

    if (!mounted) return;

    if (financeUpdated && jarsUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('update_success'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLabel('update_error'))),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 32,
      vertical: isMobile ? 20 : 32,
    );

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _totalPercent();
    final totalOk = total == 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_getLabel('title')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                title: _getLabel('financial'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelText(_getLabel('monthly_income')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        hintText: _getLabel('monthly_income_hint'),
                        prefixText: _currency == 'USD' ? '\$ ' : '₫ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labelText(_getLabel('salary_day')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _payDayController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        hintText: _getLabel('salary_day_hint'),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionCard(
                title: _getLabel('allocation'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: totalOk
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_getLabel('total')}: $total% ${totalOk ? _getLabel('total_ok') : ''}',
                    style: TextStyle(
                      color: totalOk
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: _jars.isEmpty
                    ? Text(
                        _getLabel('no_profile'),
                        style: const TextStyle(color: Color(0xFF64748B)),
                      )
                    : Column(
                        children: List.generate(_jars.length, (index) {
                          final jar = _jars[index];
                          final color = _parseColor(jar['color']?.toString());
                          final percent =
                              (jar['percent'] as num?)?.toDouble() ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconFromName(jar['icon']?.toString()),
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _jarDisplayName(jar['name']?.toString()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 68,
                                      child: TextField(
                                        controller: _percentControllers[index],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        decoration: _inputDecoration(
                                          suffixText: '%',
                                          compact: true,
                                        ),
                                        onChanged: (value) {
                                          final newValue =
                                              int.tryParse(value) ?? 0;
                                          final clamped =
                                              newValue.clamp(0, 100).toInt();
                                          setState(() {
                                            jar['percent'] = clamped;
                                            if (clamped.toString() !=
                                                _percentControllers[index]
                                                    .text) {
                                              _percentControllers[index].text =
                                                  clamped.toString();
                                              _percentControllers[index]
                                                      .selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(
                                                  offset: _percentControllers[index]
                                                      .text
                                                      .length,
                                                ),
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: percent.clamp(0, 100),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  activeColor: color,
                                  onChanged: (value) {
                                    setState(() {
                                      final newValue = value.round();
                                      jar['percent'] = newValue;
                                      _percentControllers[index].text =
                                          newValue.toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
              ),
              const SizedBox(height: 20),
              _sectionCard(
                title: _getLabel('language'),
                child: Column(
                  children: [
                    _languageOption(
                      title: _getLabel('vietnamese'),
                      subtitle: 'VND',
                      isSelected: _currency == 'VND',
                      onTap: () => _updateCurrency('VND'),
                    ),
                    const SizedBox(height: 12),
                    _languageOption(
                      title: _getLabel('english'),
                      subtitle: 'USD',
                      isSelected: _currency == 'USD',
                      onTap: () => _updateCurrency('USD'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionCard(
                title: _getLabel('theme'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getLabel('theme_light'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _getLabel('coming_soon'),
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving ? _getLabel('saving') : _getLabel('save'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _languageOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color:
                  isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5F5),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? prefixText,
    String? suffixText,
    Widget? prefixIcon,
    bool compact = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF0F172A),
      ),
    );
  }
}
