import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/jarprofile_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditExpenseScreen({super.key, required this.transaction});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final TransactionService _service = TransactionService();
  final JarProfileService _jarProfileService = JarProfileService();

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  bool _isLoading = false;
  bool _isLoadingJars = true;

  late String _selectedJarKey;
  late String _selectedCurrency;
  late DateTime _selectedDate;

  // Fetched from API
  Map<String, String> jarMap = {};

  final List<String> currencies = ["VND", "USD"];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: (tx['amount'] ?? 0).toString());
    _noteController = TextEditingController(text: tx['note'] ?? '');
    _selectedJarKey = tx['jar_key'] ?? '';
    _selectedCurrency = tx['currency'] ?? 'VND';

    try {
      _selectedDate = DateTime.parse(tx['occurred_at']);
    } catch (_) {
      _selectedDate = DateTime.now();
    }

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
        // Ensure selected jar exists in map
        if (!jarMap.containsKey(_selectedJarKey) && jarMap.isNotEmpty) {
          _selectedJarKey = jarMap.keys.first;
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateExpense() async {
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

    setState(() => _isLoading = true);

    final result = await _service.updateExpense(
      id: widget.transaction['_id'],
      amount: amount,
      jarKey: _selectedJarKey,
      note: _noteController.text.trim(),
      occurredAt: _selectedDate,
      currency: _selectedCurrency,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Cập nhật thành công'),
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

  void _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá giao dịch này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await _service.deleteExpense(widget.transaction['_id']);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      ),
    );

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Sửa chi tiêu', style: TextStyle(color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isLoading ? null : _deleteExpense,
            tooltip: 'Xoá giao dịch',
          ),
        ],
      ),
      body: _isLoadingJars
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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

                          const SizedBox(height: 20),

                          // Jar
                          const Text('Chọn lọ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: jarMap.containsKey(_selectedJarKey) ? _selectedJarKey : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
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
                              if (value != null) setState(() => _selectedJarKey = value);
                            },
                          ),

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
                          const Text('Ngày chi', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
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
                              hintText: 'Nhập ghi chú...',
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

                    // Buttons
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
                            onPressed: _isLoading ? null : _updateExpense,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Cập nhật',
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
