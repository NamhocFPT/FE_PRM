import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/jarprofile_service.dart';
import 'main_wrapper.dart';
import 'income_setup_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final AuthService _authService = AuthService();
  final JarProfileService _jarProfileService = JarProfileService();
  bool _isLoading = false;

  Future<void> _selectLanguage(String currency, String language) async {
    setState(() => _isLoading = true);

    try {
      // Cập nhật currency lên server
      final response = await _authService.updateCurrency(currency);

      if (!mounted) return;

      if (response) {
        // Check xem user có active jar profile chưa
        final hasActive = await _jarProfileService.hasActiveProfile();

        if (!mounted) return;

        if (hasActive) {
          // User có active profile rồi → đi đến MainWrapper
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainWrapper(),
            ),
          );
        } else {
          // User chưa có active profile → đi đến IncomeSetupScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const IncomeSetupScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật ngôn ngữ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.language,
                  size: 80,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Chọn Ngôn Ngữ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lựa chọn ngôn ngữ và tiền tệ để sử dụng',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 48),
                // Tiếng Việt (VND) Card
                _LanguageCard(
                  isLoading: _isLoading,
                  title: 'Tiếng Việt',
                  subtitle: 'Vietnamese',
                  currency: '₫ (VND)',
                  flag: '🇻🇳',
                  icon: Icons.settings_suggest,
                  bgColor: const Color(0xFFF97316),
                  onTap: () => _selectLanguage('VND', 'vi'),
                ),
                const SizedBox(height: 16),
                // Tiếng Anh (USD) Card
                _LanguageCard(
                  isLoading: _isLoading,
                  title: 'English',
                  subtitle: 'English (US)',
                  currency: '\$ (USD)',
                  flag: '🇺🇸',
                  icon: Icons.settings_suggest,
                  bgColor: const Color(0xFF3B82F6),
                  onTap: () => _selectLanguage('USD', 'en'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String currency;
  final String flag;
  final IconData icon;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.currency,
    required this.flag,
    required this.icon,
    required this.bgColor,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: bgColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: bgColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
