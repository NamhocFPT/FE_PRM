class IncomeEventModel {
  final String id;
  final double amount;
  final String source;
  final String note;
  final DateTime receivedAt;
  final String currency;
  final List<IncomeAllocation> allocations;

  const IncomeEventModel({
    required this.id,
    required this.amount,
    required this.source,
    required this.note,
    required this.receivedAt,
    required this.currency,
    required this.allocations,
  });

  factory IncomeEventModel.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'];
    return IncomeEventModel(
      id: (json['_id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      source: (json['source'] ?? 'Khác').toString(),
      note: (json['note'] ?? '').toString(),
      receivedAt: DateTime.tryParse((json['received_at'] ?? '').toString()) ?? DateTime.now(),
      currency: (json['currency'] ?? 'VND').toString(),
      allocations: rawAllocations is List
          ? rawAllocations
              .whereType<Map>()
              .map((e) => IncomeAllocation.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class IncomeAllocation {
  final String jarKey;
  final double percent;
  final double amount;

  const IncomeAllocation({
    required this.jarKey,
    required this.percent,
    required this.amount,
  });

  factory IncomeAllocation.fromJson(Map<String, dynamic> json) {
    return IncomeAllocation(
      jarKey: (json['jar_key'] ?? '').toString(),
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class JarBalanceCardModel {
  final String jarKey;
  final String jarName;
  final String iconName;
  final String colorHex;
  final double percent;
  final double currentBalance;
  final double allocatedThisMonth;
  final double spentThisMonth;
  final int movementCount;

  const JarBalanceCardModel({
    required this.jarKey,
    required this.jarName,
    required this.iconName,
    required this.colorHex,
    required this.percent,
    required this.currentBalance,
    required this.allocatedThisMonth,
    required this.spentThisMonth,
    required this.movementCount,
  });

  double get balance => currentBalance;

  double get progressPercent {
    if (allocatedThisMonth <= 0) return 0;
    return (spentThisMonth / allocatedThisMonth) * 100;
  }

  bool get isOverBudget => allocatedThisMonth > 0 && spentThisMonth > allocatedThisMonth;
}

class JarLedgerEntryModel {
  final String id;
  final String jarKey;
  final double delta;
  final String refType;
  final DateTime occurredAt;
  final Map<String, dynamic>? refData;

  const JarLedgerEntryModel({
    required this.id,
    required this.jarKey,
    required this.delta,
    required this.refType,
    required this.occurredAt,
    required this.refData,
  });

  factory JarLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final rawRefData = json['ref_id'];
    return JarLedgerEntryModel(
      id: (json['_id'] ?? '').toString(),
      jarKey: (json['jar_key'] ?? '').toString(),
      delta: (json['delta'] as num?)?.toDouble() ?? 0,
      refType: (json['ref_type'] ?? '').toString(),
      occurredAt: DateTime.tryParse((json['occurred_at'] ?? '').toString()) ?? DateTime.now(),
      refData: rawRefData is Map ? Map<String, dynamic>.from(rawRefData) : null,
    );
  }
}
