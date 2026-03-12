import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/jarprofile_service.dart';
import '../services/auth_service.dart';
import 'main_wrapper.dart';

class IncomeSetupScreen extends StatefulWidget {
  const IncomeSetupScreen({super.key});

  @override
  State<IncomeSetupScreen> createState() => _IncomeSetupScreenState();
}

class _IncomeSetupScreenState extends State<IncomeSetupScreen> {
  final JarProfileService _jarProfileService = JarProfileService();
  final AuthService _authService = AuthService();
  final _incomeController = TextEditingController(text: '10000000');
  final _salaryDayController = TextEditingController(text: '1');
  bool _isLoading = false;
  String currency = 'VND'; // Default to VND

  final currencySymbols = {
    'VND': '₫',
    'USD': '\$',
  };

  final currencyLabels = {
    'VND': 'Thu nhập hàng tháng (VND)',
    'USD': 'Monthly Income (USD)',
  };

  final titleLabels = {
    'VND': 'Thiết lập thu nhập',
    'USD': 'Income Setup',
  };

  final subtitleLabels = {
    'VND': 'Cho chúng tôi biết thu nhập hàng tháng của bạn',
    'USD': 'Let us know your monthly income',
  };

  final salaryDayLabels = {
    'VND': 'Ngày nhận lương',
    'USD': 'Salary Payment Day',
  };

  final salaryDayHelpLabels = {
    'VND': 'Ngày trong tháng bạn nhận lương (1-31)',
    'USD': 'Day of month you receive salary (1-31)',
  };

  final incomeHelpLabels = {
    'VND': 'Nhập số tiền thu nhập hàng tháng',
    'USD': 'Enter monthly income amount',
  };

  final tipsLabels = {
    'VND': '💡 Mẹo: Hãy nhập thu nhập thực tế sau thuế để có kế hoạch tài chính chính xác hơn.',
    'USD': '💡 Tip: Enter your after-tax income for accurate financial planning.',
  };

  final buttonLabels = {
    'VND': 'Tiếp tục',
    'USD': 'Continue',
  };

  final errorLabels = {
    'invalid_income': {
      'VND': 'Vui lòng nhập thu nhập hợp lệ',
      'USD': 'Please enter a valid income',
    },
    'invalid_day': {
      'VND': 'Vui lòng nhập ngày từ 1-31',
      'USD': 'Please enter a day between 1 and 31',
    },
    'profiles_failed': {
      'VND': 'Không thể lấy danh sách hồ sơ',
      'USD': 'Unable to load profiles',
    },
    'create_failed': {
      'VND': 'Không thể tạo hồ sơ',
      'USD': 'Unable to create profile',
    },
    'activate_failed': {
      'VND': 'Không thể kích hoạt hồ sơ',
      'USD': 'Unable to activate profile',
    },
    'error_prefix': {
      'VND': 'Lỗi: ',
      'USD': 'Error: ',
    },
    'update_failed': {
      'VND': 'Không thể lưu thông tin tài chính',
      'USD': 'Unable to save financial info',
    },
  };

  String _errorText(String key) {
    final map = errorLabels[key];
    if (map is Map<String, String>) {
      return map[currency] ?? map['VND'] ?? '';
    }
    return '';
  }

  String _formatWithDots(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _formattedIncomeText() {
    final formatted = _formatWithDots(_incomeController.text);
    if (formatted.isEmpty) return '';
    final symbol = currencySymbols[currency] ?? '₫';
    return '$formatted $symbol';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (userProfile != null && userProfile['currency'] != null) {
        setState(() {
          currency = userProfile['currency'];
        });
      }
    } catch (e) {
      print('Error loading currency: $e');
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _salaryDayController.dispose();
    super.dispose();
  }

  Future<void> _setupIncome() async {
    // Validate inputs
    final income = int.tryParse(_incomeController.text);
    final salaryDay = int.tryParse(_salaryDayController.text);

    if (income == null || income <= 0) {
      _showError(_errorText('invalid_income'));
      return;
    }

    if (salaryDay == null || salaryDay < 1 || salaryDay > 31) {
      _showError(_errorText('invalid_day'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final financeUpdated =
          await _authService.updateFinancialInfo(income, salaryDay);
      if (!financeUpdated) {
        _showError(_errorText('update_failed'));
        return;
      }

      final profiles = await _jarProfileService.getAllProfiles();
      if (profiles == null) {
        _showError(_errorText('profiles_failed'));
        return;
      }

      Map<String, dynamic>? profile;
      if (profiles.isEmpty) {
        final profileName = currency == 'USD'
            ? 'Default Profile'
            : 'Hồ sơ mặc định';
        profile = await _jarProfileService.createProfile(profileName);
        if (profile == null) {
          _showError(_errorText('create_failed'));
          return;
        }
      } else {
        profile = profiles.first;
      }

      final profileId = profile['_id']?.toString();
      final isActive = profile['is_active'] == true;
      if (!isActive && profileId != null) {
        final activated =
            await _jarProfileService.activateProfile(profileId);
        if (!activated) {
          _showError(_errorText('activate_failed'));
          return;
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainWrapper(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('${_errorText('error_prefix')}$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final symbol = currencySymbols[currency] ?? '₫';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: isMobile ? 24 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.attach_money_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        titleLabels[currency] ?? 'Thiết lập thu nhập',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitleLabels[currency] ??
                            'Cho chúng tôi biết thu nhập hàng tháng của bạn',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form Card
                Container(
                  padding: EdgeInsets.all(isMobile ? 20 : 32),
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
                      // Income Input
                      Text(
                        currencyLabels[currency] ??
                            'Thu nhập hàng tháng (VND)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _incomeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '10000000',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          prefixText: '$symbol  ',
                          prefixStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_formattedIncomeText().isNotEmpty)
                        Text(
                          _formattedIncomeText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        incomeHelpLabels[currency] ??
                            'Nhập số tiền thu nhập hàng tháng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Salary Day Input
                      Text(
                        salaryDayLabels[currency] ?? 'Ngày nhận lương',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _salaryDayController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '1',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        salaryDayHelpLabels[currency] ??
                            'Ngày trong tháng bạn nhận lương (1-31)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Tips Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFCD34D),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tipsLabels[currency] ??
                        '💡 Mẹo: Hãy nhập thu nhập thực tế sau thuế để có kế hoạch tài chính chính xác hơn.',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.orange.shade900,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed: _isLoading ? null : _setupIncome,
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange.shade600,
                              ),
                            ),
                          )
                        : Text(
                            buttonLabels[currency] ?? 'Tiếp tục',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
