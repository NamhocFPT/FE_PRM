import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  String? _errorMessage;

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  double _currentMonthIncome = 0;
  double _currentMonthExpense = 0;
  double _lastMonthIncome = 0;
  double _lastMonthExpense = 0;

  static final List<String> _monthNames = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  String _formatMonthString(int month, int year) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentMonthStr = _formatMonthString(_currentMonth, _currentYear);
      
      int lastMonthVal = _currentMonth == 1 ? 12 : _currentMonth - 1;
      int lastMonthYear = _currentMonth == 1 ? _currentYear - 1 : _currentYear;
      final lastMonthStr = _formatMonthString(lastMonthVal, lastMonthYear);

      final results = await Future.wait([
        _dashboardService.getMonthlyDashboard(currentMonthStr),
        _dashboardService.getMonthlyDashboard(lastMonthStr),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentMonthIncome = (results[0]['total_income'] ?? 0).toDouble();
        _currentMonthExpense = (results[0]['total_expense'] ?? 0).toDouble();
        _lastMonthIncome = (results[1]['total_income'] ?? 0).toDouble();
        _lastMonthExpense = (results[1]['total_expense'] ?? 0).toDouble();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatCurrency(double value) {
    final intValue = value.toInt();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
        buffer.write(str[i]);
    }
    return '$buffer ₫';
  }

  double _percentChange(double current, double previous) {
    if (previous <= 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo tháng')),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    final currentSavings = _currentMonthIncome - _currentMonthExpense;
    final lastSavings = _lastMonthIncome - _lastMonthExpense;

    final incomeChange = _percentChange(_currentMonthIncome, _lastMonthIncome);
    final expenseChange = _percentChange(_currentMonthExpense, _lastMonthExpense);
    final savingsChange = _percentChange(currentSavings, lastSavings);

    final double incomeTarget = _currentMonthIncome > 0 ? _currentMonthIncome : 10000000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.2),
                             shape: BoxShape.circle,
                          ),
                          child: const Icon(
                             Icons.arrow_back,
                             color: Colors.white,
                             size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Báo cáo tháng',
                        style: TextStyle(
                           color: Colors.white,
                           fontSize: 22,
                           fontWeight: FontWeight.bold,
                        ),
                      ),
                     ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                     padding: const EdgeInsets.only(left: 52),
                     child: Text(
                        '${_monthNames[_currentMonth - 1]} $_currentYear',
                        style: TextStyle(
                           color: Colors.white.withOpacity(0.8),
                           fontSize: 14,
                        ),
                     ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSavingsCard(currentSavings, lastSavings, savingsChange),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Tổng thu nhập',
                    currentValue: _currentMonthIncome,
                    previousValue: _lastMonthIncome,
                    change: incomeChange,
                    valueColor: const Color(0xFF22C55E),
                    positiveIsGood: true,
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Tổng chi tiêu',
                    currentValue: _currentMonthExpense,
                    previousValue: _lastMonthExpense,
                    change: expenseChange,
                    valueColor: const Color(0xFFEF4444),
                    positiveIsGood: false,
                  ),
                  const SizedBox(height: 16),

                  _buildComparisonCard(
                    _currentMonthIncome,
                    _currentMonthExpense,
                    incomeTarget,
                  ),
                  const SizedBox(height: 16),

                  if (currentSavings > 0)
                    _buildCelebrationCard(currentSavings, _currentMonth - 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(
    double currentSavings,
    double lastSavings,
    double savingsChange,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF059669)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiết kiệm tháng này',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
              if (savingsChange != 0) _buildChangeBadge(savingsChange, true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(currentSavings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tháng trước: ${_formatCurrency(lastSavings)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double currentValue,
    required double previousValue,
    required double change,
    required Color valueColor,
    required bool positiveIsGood,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (change != 0)
                _buildChangeBadge(change, positiveIsGood),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(currentValue),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tháng trước: ${_formatCurrency(previousValue)}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBadge(double change, bool positiveIsGood) {
    final isPositive = change > 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final lightColor = isGood
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lightColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_outward
                : Icons.south_east,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 3),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    double currentIncome,
    double currentExpense,
    double incomeTarget,
  ) {
    final incomePercent = (currentIncome / incomeTarget * 100).clamp(0.0, 100.0);
    final expensePercent = (currentExpense / incomeTarget * 100).clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So sánh với tháng trước',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressBar(
            label: 'Thu nhập',
            percent: incomePercent,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            label: 'Chi tiêu',
            percent: expensePercent,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percent,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCelebrationCard(double savings, int month) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Tuyệt vời! Bạn đã tiết kiệm được',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(savings),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'trong ${_monthNames[month].toLowerCase()}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
