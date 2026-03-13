import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/goal_service.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  final GoalService _goalService = GoalService();

  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  bool _showAddForm = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;

  // Custom add-money controller (for dialog)
  final _customAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _deadlineCtrl.dispose();
    _customAmountCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _fmt(double value) {
    final intVal = value.toInt();
    final str = intVal.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '$buf ₫';
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _goalId(Map<String, dynamic> g) =>
      (g['_id'] ?? g['id'] ?? '').toString();

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── API calls ──────────────────────────────────────────────────────────

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await _goalService.getGoals();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _submitGoal() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || amount <= 0) {
      _snack('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _goalService.createGoal(
      name: name,
      targetAmount: amount,
      deadline: _selectedDeadline?.toIso8601String().split('T').first,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      _snack('Đã thêm mục tiêu!');
      _nameCtrl.clear();
      _amountCtrl.clear();
      _deadlineCtrl.clear();
      _selectedDeadline = null;
      setState(() => _showAddForm = false);
      await _loadGoals();
    } else {
      _snack('Không thể tạo mục tiêu', isError: true);
    }
  }

  Future<void> _addMoney(String goalId, double amount) async {
    final ok = await _goalService.addProgress(goalId, amount);
    if (!mounted) return;
    if (ok) {
      _snack('Đã thêm ${_fmt(amount)}');
      await _loadGoals();
    } else {
      _snack('Cộng tiền thất bại', isError: true);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF59E0B),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineCtrl.text = _fmtDate(picked.toIso8601String());
      });
    }
  }

  void _showCustomAmountDialog(String goalId, double remaining) {
    _customAmountCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Nhập số tiền'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customAmountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  hintText: 'Số tiền muốn cộng',
                  suffixText: '₫',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if ((double.tryParse(_customAmountCtrl.text) ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    _fmt(double.tryParse(_customAmountCtrl.text) ?? 0),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final val = double.tryParse(_customAmountCtrl.text) ?? 0;
                Navigator.pop(ctx);
                if (val > 0) {
                  _addMoney(goalId, val);
                }
              },
              child: const Text(
                'Cộng tiền',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit goal dialog ───────────────────────────────────────────────────

  void _showEditGoalDialog(Map<String, dynamic> goal) {
    final id = _goalId(goal);
    final origName = (goal['name'] ?? '').toString();
    final origTarget = _toDouble(goal['target_amount']);
    final origCurrent = _toDouble(goal['current_amount']);
    final origDeadline = goal['deadline']?.toString() ?? '';
    final origStatus = (goal['status'] ?? 'ACTIVE').toString().toUpperCase();

    final editNameCtrl = TextEditingController(text: origName);
    final editTargetCtrl = TextEditingController(
      text: origTarget > 0 ? origTarget.toInt().toString() : '',
    );
    final editCurrentCtrl = TextEditingController(
      text: origCurrent > 0 ? origCurrent.toInt().toString() : '0',
    );
    final editDeadlineCtrl = TextEditingController(
      text: _fmtDate(origDeadline),
    );

    String selectedStatus = origStatus;
    DateTime? editDeadlineDate;
    if (origDeadline.isNotEmpty) {
      try {
        editDeadlineDate = DateTime.parse(origDeadline);
      } catch (_) {}
    }
    bool isSavingEdit = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickEditDeadline() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: editDeadlineDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (c, child) => Theme(
                  data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFFF59E0B),
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setModalState(() {
                  editDeadlineDate = picked;
                  editDeadlineCtrl.text = _fmtDate(picked.toIso8601String());
                });
              }
            }

            Future<void> saveEdit() async {
              final body = <String, dynamic>{};

              final newName = editNameCtrl.text.trim();
              if (newName.isNotEmpty && newName != origName) {
                body['name'] = newName;
              }

              final newTarget = double.tryParse(editTargetCtrl.text.trim()) ?? 0;
              if (newTarget > 0 && newTarget != origTarget) {
                body['target_amount'] = newTarget;
              }

              final newCurrent = double.tryParse(editCurrentCtrl.text.trim()) ?? 0;
              if (newCurrent != origCurrent) {
                body['current_amount'] = newCurrent;
              }

              if (editDeadlineDate != null) {
                final newDl = editDeadlineDate!.toIso8601String().split('T').first;
                if (newDl != origDeadline.split('T').first) {
                  body['deadline'] = newDl;
                }
              }

              if (selectedStatus != origStatus) {
                body['status'] = selectedStatus;
              }

              if (body.isEmpty) {
                Navigator.pop(ctx);
                return;
              }

              setModalState(() => isSavingEdit = true);
              final ok = await _goalService.updateGoal(id, body);
              if (!mounted) return;
              setModalState(() => isSavingEdit = false);

              Navigator.pop(ctx);
              if (ok) {
                _snack('Cập nhật mục tiêu thành công!');
                await _loadGoals();
              } else {
                _snack('Cập nhật thất bại', isError: true);
              }
            }

            return Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(ctx).padding.top + 60,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chỉnh sửa mục tiêu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      _label('Tên mục tiêu'),
                      const SizedBox(height: 6),
                      _editField(editNameCtrl, 'Tên mục tiêu'),
                      const SizedBox(height: 14),

                      // Target amount
                      _label('Số tiền mục tiêu (VNĐ)'),
                      const SizedBox(height: 6),
                      _editField(editTargetCtrl, '0', isNumber: true, prefixText: '₫ ', onChanged: (_) => setModalState(() {})),
                      if ((double.tryParse(editTargetCtrl.text) ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fmt(double.tryParse(editTargetCtrl.text) ?? 0),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Current amount
                      _label('Số tiền hiện tại (VNĐ)'),
                      const SizedBox(height: 6),
                      _editField(editCurrentCtrl, '0', isNumber: true, prefixText: '₫ ', onChanged: (_) => setModalState(() {})),
                      if ((double.tryParse(editCurrentCtrl.text) ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fmt(double.tryParse(editCurrentCtrl.text) ?? 0),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Deadline
                      _label('Thời hạn'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: pickEditDeadline,
                        child: AbsorbPointer(
                          child: _editField(
                            editDeadlineCtrl,
                            'Chọn ngày',
                            prefixIcon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status
                      _label('Trạng thái'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusChip('ACTIVE', 'Đang thực hiện', selectedStatus, (v) {
                            setModalState(() => selectedStatus = v);
                          }),
                          const SizedBox(width: 8),
                          _statusChip('PAUSED', 'Tạm dừng', selectedStatus, (v) {
                            setModalState(() => selectedStatus = v);
                          }),
                          const SizedBox(width: 8),
                          _statusChip('DONE', 'Hoàn thành', selectedStatus, (v) {
                            setModalState(() => selectedStatus = v);
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isSavingEdit ? null : saveEdit,
                              child: isSavingEdit
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Lưu thay đổi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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
          },
        );
      },
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
    String? prefixText,
    IconData? prefixIcon,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _statusChip(
    String value,
    String label,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final isActive = value == selected;
    Color bg;
    Color fg;
    switch (value) {
      case 'DONE':
        bg = isActive ? const Color(0xFF22C55E) : const Color(0xFFDCFCE7);
        fg = isActive ? Colors.white : const Color(0xFF15803D);
        break;
      case 'PAUSED':
        bg = isActive ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7);
        fg = isActive ? Colors.white : const Color(0xFF92400E);
        break;
      default:
        bg = isActive ? const Color(0xFF3B82F6) : const Color(0xFFEFF6FF);
        fg = isActive ? Colors.white : const Color(0xFF1D4ED8);
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? null : Border.all(color: bg),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : RefreshIndicator(
              color: const Color(0xFFF59E0B),
              onRefresh: _loadGoals,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Body ──
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Add/Toggle button
                        _showAddForm ? _buildForm() : _buildAddButton(),
                        const SizedBox(height: 20),

                        // Goal list or empty state
                        if (_goals.isEmpty) _buildEmpty(),
                        ..._goals.map(_buildGoalCard),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
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
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Mục tiêu tiết kiệm',
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
              '${_goals.length} mục tiêu đang theo dõi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add button ─────────────────────────────────────────────────────────

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        onPressed: () => setState(() => _showAddForm = true),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm mục tiêu mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  // ── Create form ────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tạo mục tiêu mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 18),

          // Name
          _label('Tên mục tiêu'),
          const SizedBox(height: 6),
          _input(_nameCtrl, 'VD: Mua laptop, Du lịch Đà Nẵng...'),
          const SizedBox(height: 14),

          // Amount
          _label('Số tiền mục tiêu (VNĐ)'),
          const SizedBox(height: 6),
          _input(_amountCtrl, '0', isNumber: true, prefixText: '₫ '),
          if (_amountCtrl.text.isNotEmpty && (double.tryParse(_amountCtrl.text) ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _fmt((double.tryParse(_amountCtrl.text) ?? 0)),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          const SizedBox(height: 14),

          // Deadline
          _label('Thời hạn (tùy chọn)'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDeadline,
            child: AbsorbPointer(
              child: _input(_deadlineCtrl, 'Chọn ngày', prefixIcon: Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: () => setState(() => _showAddForm = false),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : _submitGoal,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tạo mục tiêu',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
      );

  Widget _input(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
    String? prefixText,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: isNumber ? (_) => setState(() {}) : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'Chưa có mục tiêu nào',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tạo mục tiêu để theo dõi kế hoạch tiết kiệm của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Goal card ──────────────────────────────────────────────────────────

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final id = _goalId(goal);
    final name = (goal['name'] ?? '').toString();
    final target = _toDouble(goal['target_amount']);
    final current = _toDouble(goal['current_amount']);
    final deadline = goal['deadline']?.toString();
    final status = (goal['status'] ?? 'ACTIVE').toString().toUpperCase();

    final isCompleted = status == 'DONE' || current >= target;
    final percentage = target > 0 ? (current / target * 100).clamp(0.0, 100.0) : 0.0;
    final remaining = (target - current).clamp(0.0, double.infinity).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
              )
            : null,
        color: isCompleted ? null : Colors.white,
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
          // ── Title row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompleted)
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 2),
                  child: Text('✅', style: TextStyle(fontSize: 22)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (deadline != null && deadline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Thời hạn: ${_fmtDate(deadline)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Edit + Status badge
              InkWell(
                onTap: () => _showEditGoalDialog(goal),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // ── Progress ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến độ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(current),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                ),
              ),
              Text(
                _fmt(target),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Completed / remaining ──
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    '🎉 Chúc mừng!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bạn đã hoàn thành mục tiêu này',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            // Remaining
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Còn thiếu:',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(remaining),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick add buttons
            Row(
              children: [
                _quickAddBtn(id, 100000, '+100K'),
                const SizedBox(width: 8),
                _quickAddBtn(id, 500000, '+500K'),
                const SizedBox(width: 8),
                _quickAddBtn(id, 1000000, '+1M'),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: () => _showCustomAmountDialog(id, remaining),
                    child: const Text(
                      'Khác',
                      style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickAddBtn(String goalId, double amount, String label) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF7ED),
          foregroundColor: const Color(0xFFF59E0B),
          elevation: 0,
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFFED7AA)),
          ),
        ),
        onPressed: () => _addMoney(goalId, amount),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String text;
    switch (status) {
      case 'DONE':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        text = 'Hoàn thành';
        break;
      case 'PAUSED':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        text = 'Tạm dừng';
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        text = 'Đang thực hiện';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
