import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/jarprofile_service.dart';
import 'AddExpenseScreen.dart';
import 'EditExpenseScreen.dart';
import 'TransferScreen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _service = TransactionService();
  final JarProfileService _jarProfileService = JarProfileService();

  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingJars = true;
  String? _errorMessage;

  // Filters
  DateTime _selectedMonth = DateTime.now();
  String _selectedJarKey = '';
  String _selectedType = '';

  // Fetched from API
  Map<String, String> jarMap = {};

  final Map<String, String> typeMap = {
    '': 'Tất cả',
    'EXPENSE': 'Chi tiêu',
    'TRANSFER': 'Chuyển tiền',
  };

  @override
  void initState() {
    super.initState();
    _loadJarsAndTransactions();
  }

  Future<void> _loadJarsAndTransactions() async {
    // Load jars first
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
      }
    });
    // Then load transactions
    await _loadTransactions();
  }

  String get _monthString {
    final y = _selectedMonth.year;
    final m = _selectedMonth.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.getTransactions(
      month: _monthString,
      jarKey: _selectedJarKey.isNotEmpty ? _selectedJarKey : null,
      type: _selectedType.isNotEmpty ? _selectedType : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _transactions = result['data'] as List<dynamic>? ?? [];
      } else {
        _errorMessage = result['message'] ?? 'Có lỗi xảy ra';
        _transactions = [];
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadTransactions();
  }

  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá giao dịch này?'),
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

    final result = await _service.deleteExpense(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      ),
    );

    if (result['success'] == true) {
      _loadTransactions();
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result == true) _loadTransactions();
  }

  void _navigateToTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransferScreen()),
    );
    if (result == true) _loadTransactions();
  }

  void _navigateToEdit(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(transaction: transaction),
      ),
    );
    if (result == true) _loadTransactions();
  }

  // Get jar display name from jarMap, fallback to key itself
  String _getJarName(String? key) {
    if (key == null || key.isEmpty) return '';
    return jarMap[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    // Build jar filter map (with "Tất cả" option)
    final jarFilterMap = <String, String>{'': 'Tất cả lọ', ...jarMap};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ─── Header gradient ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Lịch sử giao dịch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Month selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _changeMonth(-1),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedMonth = picked);
                          _loadTransactions();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Filter chips ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    value: jarFilterMap.containsKey(_selectedJarKey) ? _selectedJarKey : '',
                    items: jarFilterMap,
                    onChanged: (v) {
                      setState(() => _selectedJarKey = v ?? '');
                      _loadTransactions();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterDropdown(
                    value: _selectedType,
                    items: typeMap,
                    onChanged: (v) {
                      setState(() => _selectedType = v ?? '');
                      _loadTransactions();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ─── Transaction list ───
          Expanded(
            child: (_isLoading || _isLoadingJars)
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _loadTransactions,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có giao dịch nào',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF6366F1),
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index] as Map<String, dynamic>;
                                return _buildTransactionCard(tx);
                              },
                            ),
                          ),
          ),
        ],
      ),

      // ─── FAB ───
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showAddOptions(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          items: items.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type = tx['type'] ?? 'EXPENSE';
    final amount = (tx['amount'] ?? 0).toDouble();
    final jarKey = tx['jar_key'] ?? tx['from_jar_key'] ?? '';
    final note = tx['note'] ?? '';
    final occurredAt = tx['occurred_at'] ?? '';
    final id = tx['_id'] ?? '';
    final currency = tx['currency'] ?? 'VND';

    final isTransfer = type == 'TRANSFER';

    // Parse date
    String dateStr = '';
    try {
      final dt = DateTime.parse(occurredAt);
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      dateStr = occurredAt.toString();
    }

    // Format amount
    final amountStr = currency == 'USD'
        ? '\$${amount.toStringAsFixed(2)}'
        : '${amount.toStringAsFixed(0)}đ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isTransfer ? const Color(0xFFFFF7ED) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isTransfer ? Icons.swap_horiz : Icons.arrow_downward,
            color: isTransfer ? const Color(0xFFF97316) : const Color(0xFF6366F1),
            size: 22,
          ),
        ),
        title: Text(
          isTransfer
              ? '${_getJarName(tx['from_jar_key']?.toString())} → ${_getJarName(tx['to_jar_key']?.toString())}'
              : _getJarName(jarKey.toString()),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isNotEmpty)
              Text(
                note,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTransfer ? amountStr : '-$amountStr',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isTransfer ? const Color(0xFFF97316) : const Color(0xFFEF4444),
              ),
            ),
            if (!isTransfer) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (action) {
                  if (action == 'edit') {
                    _navigateToEdit(tx);
                  } else if (action == 'delete') {
                    _deleteTransaction(id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Color(0xFF6366F1)),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Xoá', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: isTransfer ? null : () => _navigateToEdit(tx),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thêm giao dịch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_circle_outline, color: Color(0xFF6366F1)),
                ),
                title: const Text('Thêm chi tiêu', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ghi nhận khoản chi', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToAdd();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz, color: Color(0xFFF97316)),
                ),
                title: const Text('Chuyển tiền giữa lọ', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Di chuyển tiền giữa các lọ', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToTransfer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
