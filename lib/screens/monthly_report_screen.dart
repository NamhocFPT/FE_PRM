import 'package:flutter/material.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  // ── Mock data ──────────────────────────────────────────────────────────
  // Thay bằng API thật sau
  static final List<Map<String, dynamic>> _mockTransactions = [
    // Tháng 3 – Thu nhập
    {'type': 'income', 'amount': 15000000, 'date': '2026-03-05'},
    {'type': 'income', 'amount': 3000000, 'date': '2026-03-15'},
    // Tháng 3 – Chi tiêu
    {'type': 'expense', 'amount': 5000000, 'date': '2026-03-02'},
    {'type': 'expense', 'amount': 2000000, 'date': '2026-03-10'},
    {'type': 'expense', 'amount': 1500000, 'date': '2026-03-18'},
    // Tháng 2 – Thu nhập
    {'type': 'income', 'amount': 14000000, 'date': '2026-02-05'},
    {'type': 'income', 'amount': 2000000, 'date': '2026-02-20'},
    // Tháng 2 – Chi tiêu
    {'type': 'expense', 'amount': 6000000, 'date': '2026-02-03'},
    {'type': 'expense', 'amount': 3000000, 'date': '2026-02-14'},
    {'type': 'expense', 'amount': 1000000, 'date': '2026-02-25'},
  ];

  static const double _mockMonthlyIncome = 18000000; // Thu nhập hàng tháng dự kiến

  // ── Helpers ────────────────────────────────────────────────────────────

  static final List<String> _monthNames = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

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

  double _sumByFilter(int month, int year, String type) {
    return _mockTransactions
        .where((t) {
          final date = DateTime.parse(t['date'] as String);
          return t['type'] == type &&
              date.month - 1 == month &&
              date.year == year;
        })
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  double _percentChange(double current, double previous) {
    if (previous <= 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month - 1; // 0-indexed
    final currentYear = now.year;
    final lastMonth = currentMonth == 0 ? 11 : currentMonth - 1;
    final lastMonthYear = currentMonth == 0 ? currentYear - 1 : currentYear;

    final currentMonthIncome = _sumByFilter(currentMonth, currentYear, 'income');
    final currentMonthExpense = _sumByFilter(currentMonth, currentYear, 'expense');
    final lastMonthIncome = _sumByFilter(lastMonth, lastMonthYear, 'income');
    final lastMonthExpense = _sumByFilter(lastMonth, lastMonthYear, 'expense');

    final currentSavings = currentMonthIncome - currentMonthExpense;
    final lastSavings = lastMonthIncome - lastMonthExpense;

    final incomeChange = _percentChange(currentMonthIncome, lastMonthIncome);
    final expenseChange = _percentChange(currentMonthExpense, lastMonthExpense);
    final savingsChange = _percentChange(currentSavings, lastSavings);

    final incomeTarget = _mockMonthlyIncome;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
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
                      '${_monthNames[currentMonth]} $currentYear',
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
                  // ── Savings card ────────────────────────────────────
                  _buildSavingsCard(currentSavings, lastSavings, savingsChange),
                  const SizedBox(height: 16),

                  // ── Income card ─────────────────────────────────────
                  _buildStatCard(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Tổng thu nhập',
                    currentValue: currentMonthIncome,
                    previousValue: lastMonthIncome,
                    change: incomeChange,
                    valueColor: const Color(0xFF22C55E),
                    positiveIsGood: true,
                  ),
                  const SizedBox(height: 16),

                  // ── Expense card ────────────────────────────────────
                  _buildStatCard(
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Tổng chi tiêu',
                    currentValue: currentMonthExpense,
                    previousValue: lastMonthExpense,
                    change: expenseChange,
                    valueColor: const Color(0xFFEF4444),
                    positiveIsGood: false,
                  ),
                  const SizedBox(height: 16),

                  // ── Comparison card ─────────────────────────────────
                  _buildComparisonCard(
                    currentMonthIncome,
                    currentMonthExpense,
                    incomeTarget,
                  ),
                  const SizedBox(height: 16),

                  // ── Celebration card ────────────────────────────────
                  if (currentSavings > 0)
                    _buildCelebrationCard(currentSavings, currentMonth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget builders ─────────────────────────────────────────────────────

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
