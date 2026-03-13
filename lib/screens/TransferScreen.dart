import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/jarprofile_service.dart';
import '../utils/jar_helpers.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TransactionService _service = TransactionService();
  final JarProfileService _jarProfileService = JarProfileService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingJars = true;

  String? _fromJarKey;
  String? _toJarKey;
  String _selectedCurrency = 'VND';
  DateTime _selectedDate = DateTime.now();

  // Fetched from API
  Map<String, String> jarMap = {};

  final List<String> currencies = ["VND", "USD"];

  @override
  void initState() {
    super.initState();
    _loadJars();
  }

  Future<void> _loadJars() async {
    final jars = await _jarProfileService.getJarList();
    if (!mounted) return;
    setState(() {
      _isLoadingJars = false;
      if (jars != null && jars.isNotEmpty) {
        jarMap = {
          for (var jar in jars)
            (jar['jar_key'] ?? jar['name'] ?? '').toString():
                (jar['name'] ?? jar['jar_key'] ?? '').toString(),
        };
        final keys = jarMap.keys.toList();
        _fromJarKey = keys.isNotEmpty ? keys[0] : null;
        _toJarKey = keys.length > 1 ? keys[1] : keys.isNotEmpty ? keys[0] : null;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapJars() {
    setState(() {
      final temp = _fromJarKey;
      _fromJarKey = _toJarKey;
      _toJarKey = temp;
    });
  }

  void _createTransfer() async {
    final amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập số tiền hợp lệ"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_fromJarKey == null || _toJarKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn lọ"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_fromJarKey == _toJarKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể chuyển tiền vào cùng một lọ"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _service.createTransfer(
      fromJarKey: _fromJarKey!,
      toJarKey: _toJarKey!,
      amount: amount,
      occurredAt: _selectedDate,
      currency: _selectedCurrency,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Chuyển tiền thành công'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Có lỗi xảy ra'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chuyển tiền giữa lọ', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
            ),
          ),
        ),
      ),
      body: _isLoadingJars
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ─── Transfer Card ───
                    Container(
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
                          // From jar
                          const Text('Từ lọ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _fromJarKey,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              prefixIcon: const Icon(Icons.outbox, color: Color(0xFFEF4444)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: jarMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _fromJarKey = value);
                            },
                          ),

                          const SizedBox(height: 12),

                          // Swap button
                          Center(
                            child: InkWell(
                              onTap: _swapJars,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.swap_vert, color: Color(0xFF6366F1)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // To jar
                          const Text('Đến lọ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _toJarKey,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              prefixIcon: const Icon(Icons.move_to_inbox, color: Color(0xFF22C55E)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: jarMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _toJarKey = value);
                            },
                          ),

                          // Warning if same jar
                          if (_fromJarKey != null && _fromJarKey == _toJarKey)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, size: 16, color: Color(0xFFF97316)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lọ nguồn và đích phải khác nhau',
                                    style: TextStyle(color: Color(0xFFF97316), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── Amount & Details Card ───
                    Container(
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
                          // Amount
                          const Text('Số tiền', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if ((num.tryParse(_amountController.text.replaceAll('.', '')) ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              JarHelpers.formatMoney(num.tryParse(_amountController.text.replaceAll('.', '')) ?? 0),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Currency
                          const Text('Loại tiền', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: currencies.map((c) {
                              return DropdownMenuItem<String>(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedCurrency = value);
                            },
                          ),

                          const SizedBox(height: 20),

                          // Date
                          const Text('Ngày chuyển', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Note
                          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Nhập ghi chú (tuỳ chọn)...',
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Buttons ───
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF94A3B8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _createTransfer,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Chuyển tiền',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
