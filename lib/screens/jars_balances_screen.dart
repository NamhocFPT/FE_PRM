import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/auth_service.dart';
import '../services/income_service.dart';
import '../services/jar_service.dart';
import '../utils/jar_helpers.dart';
import 'add_income_screen.dart';
import 'jar_ledger_history_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';

class JarsBalancesScreen extends StatefulWidget {
  const JarsBalancesScreen({super.key});

  @override
  State<JarsBalancesScreen> createState() => _JarsBalancesScreenState();
}

class _JarsBalancesScreenState extends State<JarsBalancesScreen> {
  final JarService _jarService = JarService();
  final IncomeService _incomeService = IncomeService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String _userName = 'User';
  List<JarBalanceCardModel> _jars = const [];
  List<IncomeEventModel> _monthlyIncomes = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _authService.getUserProfile(),
        _jarService.getDashboardJars(month: now),
        _incomeService.getIncomeHistory(month: JarHelpers.monthKey(now)),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final jars = results[1] as List<JarBalanceCardModel>;
      final incomes = results[2] as List<IncomeEventModel>;

      if (!mounted) return;
      setState(() {
        _userName = (profile?['full_name'] ?? 'User').toString();
        _jars = jars;
        _monthlyIncomes = incomes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToAddIncome() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
    if (changed == true) {
      await _loadData();
    }
  }

  void _showExpenseComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final maxContentWidth = isMobile ? screenWidth : 1160.0;

    final totalBalance = _jars.fold<double>(0, (sum, item) => sum + item.currentBalance);
    final totalIncome = _monthlyIncomes.fold<double>(0, (sum, item) => sum + item.amount);
    final totalSpent = _jars.fold<double>(0, (sum, item) => sum + item.spentThisMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(isMobile ? 24 : 24, 24, isMobile ? 24 : 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Xin chào,',
                                            style: TextStyle(
                                              color: Color(0xFFDBEAFE),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _userName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: isMobile ? 24 : 44,
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                            );
                                          },
                                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white24,
                                            minimumSize: const Size(48, 48),
                                          ),
                                        ),
                                        Positioned(
                                          right: 10,
                                          top: 8,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isMobile ? 24 : 26),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tổng số dư',
                                        style: TextStyle(
                                          color: Color(0xFFE0E7FF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        JarHelpers.formatMoney(totalBalance),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 28 : 46,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      Wrap(
                                        spacing: 28,
                                        runSpacing: 12,
                                        children: [
                                          _TopMetric(label: 'Thu nhập', value: JarHelpers.formatMoney(totalIncome)),
                                          _TopMetric(label: 'Đã chi', value: JarHelpers.formatMoney(totalSpent)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: ElevatedButton.icon(
                                        onPressed: _showExpenseComingSoon,
                                        icon: const Icon(Icons.add_rounded, size: 20),
                                        label: const Text('Chi tiêu'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF020617),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: _goToAddIncome,
                                        icon: const Icon(Icons.trending_up_rounded, size: 20),
                                        label: const Text('Thu nhập'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF020617),
                                          side: const BorderSide(color: Color(0xFFD4D4D8)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '6 Chiếc Lọ',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                      );
                                      if (context.mounted) {
                                        await _loadData();
                                      }
                                    },
                                    child: const Text(
                                      'Chỉnh sửa',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final crossAxisCount = width >= 1100
                                      ? 4
                                      : width >= 760
                                          ? 3
                                          : 2;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _jars.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: isMobile ? 0.88 : 1.02,
                                    ),
                                    itemBuilder: (context, index) {
                                      final jar = _jars[index];
                                      return _JarCard(
                                        jar: jar,
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => JarLedgerHistoryScreen(jar: jar)),
                                          );
                                          await _loadData();
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
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
}

class _TopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDBEAFE),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _JarCard extends StatelessWidget {
  final JarBalanceCardModel jar;
  final VoidCallback onTap;

  const _JarCard({required this.jar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = JarHelpers.hexToColor(jar.colorHex);
    final icon = JarHelpers.iconFromName(jar.iconName);
    final progress = jar.progressPercent.clamp(0, 100).toDouble();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jar.jarName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${jar.percent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(jar.isOverBudget ? const Color(0xFF111827) : color),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      JarHelpers.formatMoney(jar.spentThisMonth),
                      style: TextStyle(
                        color: jar.isOverBudget ? const Color(0xFFDC2626) : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: jar.isOverBudget ? FontWeight.w700 : FontWeight.w500,
                        decoration: jar.isOverBudget ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    JarHelpers.formatMoney(jar.allocatedThisMonth),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (jar.isOverBudget) ...[
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'Vượt quỹ',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
