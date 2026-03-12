import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/income_service.dart';
import '../services/jarprofile_service.dart';
import '../utils/jar_helpers.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final IncomeService _incomeService = IncomeService();
  final JarProfileService _jarProfileService = JarProfileService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedSource = _incomeSources.first;
  List<Map<String, dynamic>> _jars = const [];

  static const List<String> _incomeSources = [
    'Lương',
    'Thưởng',
    'Kinh doanh',
    'Đầu tư',
    'Làm thêm',
    'Quà tặng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveProfile();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProfile() async {
    try {
      final profile = await _jarProfileService.getActiveProfile();
      if (!mounted) return;
      setState(() {
        _jars = profile?['jars'] is List
            ? List<Map<String, dynamic>>.from((profile?['jars'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
            : const [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  num get _amount => num.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

  List<Map<String, dynamic>> get _allocations {
    final amount = _amount;
    if (amount <= 0 || _jars.isEmpty) return const [];

    num remaining = amount;
    int biggestIndex = 0;
    final items = <Map<String, dynamic>>[];

    for (int i = 0; i < _jars.length; i++) {
      final jar = _jars[i];
      final percent = (jar['percent'] as num?) ?? 0;
      if (percent > ((_jars[biggestIndex]['percent'] as num?) ?? 0)) {
        biggestIndex = i;
      }
      final allocated = ((amount * percent) / 100).floor();
      remaining -= allocated;
      items.add({
        'name': jar['name'],
        'icon': jar['icon'],
        'color': jar['color'],
        'percent': percent,
        'amount': allocated,
      });
    }

    if (items.isNotEmpty && remaining != 0) {
      items[biggestIndex]['amount'] = ((items[biggestIndex]['amount'] as num?) ?? 0) + remaining;
    }

    return items;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount <= 0) {
      _showMessage('Vui lòng nhập số tiền hợp lệ.', isError: true);
      return;
    }
    if (_jars.isEmpty) {
      _showMessage('Chưa có jar profile active. Hãy hoàn thành UC-04 trước.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _incomeService.addIncome(
        amount: amount,
        source: _selectedSource,
        receivedAt: _selectedDate,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Đã thêm thu nhập và tự động phân bổ vào 6 lọ.');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thêm thu nhập',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thu nhập sẽ được tự động phân bổ vào 6 lọ',
                    style: TextStyle(color: Color(0xFFDCFCE7), fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Số tiền (VNĐ)'),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                        ),
                      ),
                    ),
                    if (_amount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        JarHelpers.formatMoney(_amount),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionLabel(label: 'Nguồn thu'),
                    DropdownButtonFormField<String>(
                      value: _selectedSource,
                      items: _incomeSources
                          .map((source) => DropdownMenuItem(value: source, child: Text(source)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedSource = value);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.sell_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(label: 'Ngày thu'),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDate,
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(label: 'Ghi chú (tùy chọn)'),
                    TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        hintText: 'Thêm ghi chú...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.notes_rounded),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    if (_allocations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phân bổ vào 6 lọ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ..._allocations.map((item) {
                              final color = JarHelpers.hexToColor(item['color']?.toString());
                              final icon = JarHelpers.iconFromName(item['icon']?.toString());
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: color.withAlpha(25),
                                      child: Icon(icon, size: 18, color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${item['name']} (${(item['percent'] as num).toStringAsFixed(0)}%)',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      '+${JarHelpers.formatMoney((item['amount'] as num).toInt())}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Lưu thu nhập'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
