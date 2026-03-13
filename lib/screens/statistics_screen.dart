import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  String? _errorMessage;

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  List<dynamic> _jarAllocations = []; // Data from Dashboard snapshot

  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  String get _monthString =>
      '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}';

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.getMonthlyDashboard(_monthString);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _monthlyIncome = (data['total_income'] ?? 0).toDouble();
        _monthlyExpense = (data['total_expense'] ?? 0).toDouble();

        // Map jars distribution correctly
        if (data['by_jar'] != null) {
          final List<dynamic> rawJars = data['by_jar'];
          // jar_key từ backend là tên tiếng Việt, map sang màu và icon
          final jarMeta = {
             'Nhu cầu thiết yếu': {'color': '#22C55E', 'icon': 'shopping_bag'},
             'Giáo dục': {'color': '#3B82F6', 'icon': 'school'},
             'Tiết kiệm dài hạn': {'color': '#EAB308', 'icon': 'piggy_bank'},
             'Giải trí': {'color': '#EC4899', 'icon': 'celebration'},
             'Tự do tài chính': {'color': '#8B5CF6', 'icon': 'trending_up'},
             'Cho đi': {'color': '#14B8A6', 'icon': 'favorite'},
          };

          final mappedJars = rawJars.where((j) => (j['expense'] ?? 0).toDouble() > 0).map((j) {
             final key = j['jar_key'] ?? '';
             final meta = jarMeta[key] ?? {'color': '#64748B', 'icon': 'category'};
             return {
               'spent_amount': (j['expense'] ?? 0).toDouble(),
               'name': key,
               'color': meta['color'],
               'icon': meta['icon'],
             };
          }).toList();

          _jarAllocations = mappedJars;
          
          // Sort by spent amount highest to lowest
          _jarAllocations.sort((a, b) {
             final spentA = (a['spent_amount'] ?? 0).toDouble();
             final spentB = (b['spent_amount'] ?? 0).toDouble();
             return spentB.compareTo(spentA);
          });
        } else {
          _jarAllocations = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _loadStatistics();
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

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.grey;
  }

  IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      case 'piggy_bank':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'favorite':
        return Icons.favorite;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _jarAllocations.isNotEmpty;
    final topJar = hasData ? _jarAllocations.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  'Tháng $_currentMonth/$_currentYear',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    final now = DateTime.now();
                    if (_currentYear < now.year || (_currentYear == now.year && _currentMonth < now.month)) {
                      _changeMonth(1);
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStatistics,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Income & Expenses Summary
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Thu nhập tháng này',
                                      amount: _monthlyIncome,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Chi tiêu tháng này',
                                      amount: _monthlyExpense,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (hasData) ...[
                                // Pie Chart Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Phân bổ chi tiêu theo lọ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          height: 250,
                                          child: PieChart(
                                            PieChartData(
                                              pieTouchData: PieTouchData(
                                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                  setState(() {
                                                    if (!event.isInterestedForInteractions ||
                                                        pieTouchResponse == null ||
                                                        pieTouchResponse.touchedSection == null) {
                                                      _touchedIndex = -1;
                                                      return;
                                                    }
                                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                                  });
                                                },
                                              ),
                                              borderData: FlBorderData(show: false),
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 40,
                                              sections: _showingSections(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Top spending jar
                                if (topJar != null)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFFED7AA), width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '🔥 Lọ chi nhiều nhất',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: _parseColor(topJar['color']).withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _parseIcon(topJar['icon']),
                                                color: _parseColor(topJar['color']),
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    topJar['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatCurrency((topJar['spent_amount'] ?? 0).toDouble()),
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // List of Jars Details
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Chi tiết từng lọ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ..._jarAllocations.map(_buildJarDetailItem),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Empty State
                                const SizedBox(height: 48),
                                Center(
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFCBD5E1)),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Chưa có dữ liệu thống kê',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bắt đầu thêm chi tiêu để xem thống kê',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required double amount, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJarDetailItem(dynamic jar) {
    final double spent = (jar['spent_amount'] ?? 0).toDouble();
    final double percentage = _monthlyExpense > 0 ? (spent / _monthlyExpense) * 100 : 0;
    final color = _parseColor(jar['color']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_parseIcon(jar['icon']), color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    jar['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                _formatCurrency(spent),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(_jarAllocations.length, (i) {
      final jar = _jarAllocations[i];
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 90.0 : 80.0;
      final double spent = (jar['spent_amount'] ?? 0).toDouble();
      final double percentage = _monthlyExpense > 0 ? (spent / _monthlyExpense) * 100 : 0;

      return PieChartSectionData(
        color: _parseColor(jar['color']),
        value: spent,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
        ),
      );
    });
  }
}
