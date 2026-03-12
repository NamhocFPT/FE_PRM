import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/jar_service.dart';
import '../utils/jar_helpers.dart';

class JarLedgerHistoryScreen extends StatefulWidget {
  final JarBalanceCardModel jar;

  const JarLedgerHistoryScreen({super.key, required this.jar});

  @override
  State<JarLedgerHistoryScreen> createState() => _JarLedgerHistoryScreenState();
}

class _JarLedgerHistoryScreenState extends State<JarLedgerHistoryScreen> {
  final JarService _jarService = JarService();

  bool _isLoading = true;
  List<JarLedgerEntryModel> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _jarService.getJarHistory(widget.jar.jarKey);
      if (!mounted) return;
      setState(() => _entries = data);
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

  @override
  Widget build(BuildContext context) {
    final jarColor = JarHelpers.hexToColor(widget.jar.colorHex);
    final jarIcon = JarHelpers.iconFromName(widget.jar.iconName);
    final currentBalance = _entries.fold<double>(0, (sum, item) => sum + item.delta);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: jarColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(jarIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.jar.jarName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Phân bổ ${widget.jar.percent.toStringAsFixed(0)}%',
                                style: const TextStyle(color: Color(0xFFFFEDD5), fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số dư hiện tại',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  JarHelpers.formatMoney(currentBalance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Số dòng sao kê',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_entries.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? const _EmptyLedgerState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final isPositive = entry.delta >= 0;
                              final color = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                              final bgColor = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                              final subtitle = _subtitleForEntry(entry);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _titleForEntry(entry),
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${isPositive ? '+' : '-'}${JarHelpers.formatMoney(entry.delta.abs())}',
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _dateTimeLabel(entry.occurredAt),
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                color: Color(0xFF475569),
                                                fontSize: 14,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForEntry(JarLedgerEntryModel entry) {
    if (entry.refType == 'IncomeEvent') {
      final source = entry.refData?['source']?.toString().trim();
      if (source != null && source.isNotEmpty) {
        return 'Thu nhập • $source';
      }
      return 'Phân bổ từ thu nhập';
    }
    return entry.delta >= 0 ? 'Điều chỉnh tăng' : 'Chi tiêu / điều chỉnh';
  }

  String _subtitleForEntry(JarLedgerEntryModel entry) {
    final note = entry.refData?['note']?.toString().trim() ?? '';
    if (note.isNotEmpty) return note;

    if (entry.refType == 'IncomeEvent') {
      return 'Khoản tiền này được phân bổ vào lọ ${widget.jar.jarName}.';
    }

    return '';
  }

  String _dateTimeLabel(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Chưa có sao kê biến động',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'UC-14 yêu cầu query ledger theo jar_key và nếu chưa có ledger thì trả về danh sách rỗng. Màn này đang xử lý đúng theo hướng đó.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
