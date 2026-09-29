class TaxSettlementSummaryModel {
  final double totalTaxCollected;
  final double pendingRemittance;
  final double pendingPayment;
  final double pendingClear;

  TaxSettlementSummaryModel({
    required this.totalTaxCollected,
    required this.pendingRemittance,
    required this.pendingPayment,
    required this.pendingClear,
  });

  factory TaxSettlementSummaryModel.fromJson(Map<String, dynamic> json) {
    return TaxSettlementSummaryModel(
      totalTaxCollected: double.tryParse('${json['total_tax_collected'] ?? 0}') ?? 0,
      pendingRemittance: double.tryParse('${json['pending_remittance'] ?? 0}') ?? 0,
      pendingPayment: double.tryParse('${json['pending_payment'] ?? 0}') ?? 0,
      pendingClear: double.tryParse('${json['pending_clear'] ?? 0}') ?? 0,
    );
  }
}

class TaxSettlementLogModel {
  final int? id;
  final String? action;
  final double amount;
  final String? reference;
  final String? note;
  final String? receipt;
  final String? createdAt;

  TaxSettlementLogModel({
    this.id,
    this.action,
    required this.amount,
    this.reference,
    this.note,
    this.receipt,
    this.createdAt,
  });

  factory TaxSettlementLogModel.fromJson(Map<String, dynamic> json) {
    return TaxSettlementLogModel(
      id: int.tryParse('${json['id'] ?? ''}'),
      action: json['action']?.toString(),
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      reference: json['reference']?.toString(),
      note: json['note']?.toString(),
      receipt: json['receipt']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class TaxSettlementModel {
  final int? id;
  final int? sellerId;
  final int? periodYear;
  final int? periodMonth;
  final String? periodLabel;
  final double taxCollected;
  final double onlineTaxCollected;
  final double codTaxCollected;
  final double amountRemitted;
  final double amountPaid;
  final String? status;
  final double pendingRemittance;
  final double pendingPayment;
  final bool canMarkPaid;
  final bool canClear;
  final List<TaxSettlementLogModel> logs;

  TaxSettlementModel({
    this.id,
    this.sellerId,
    this.periodYear,
    this.periodMonth,
    this.periodLabel,
    required this.taxCollected,
    required this.onlineTaxCollected,
    required this.codTaxCollected,
    required this.amountRemitted,
    required this.amountPaid,
    this.status,
    required this.pendingRemittance,
    required this.pendingPayment,
    required this.canMarkPaid,
    required this.canClear,
    required this.logs,
  });

  factory TaxSettlementModel.fromJson(Map<String, dynamic> json) {
    final logsRaw = json['logs'];
    final logs = <TaxSettlementLogModel>[];
    if (logsRaw is List) {
      for (final item in logsRaw) {
        if (item is Map<String, dynamic>) {
          logs.add(TaxSettlementLogModel.fromJson(item));
        }
      }
    }

    return TaxSettlementModel(
      id: int.tryParse('${json['id'] ?? ''}'),
      sellerId: int.tryParse('${json['seller_id'] ?? ''}'),
      periodYear: int.tryParse('${json['period_year'] ?? ''}'),
      periodMonth: int.tryParse('${json['period_month'] ?? ''}'),
      periodLabel: json['period_label']?.toString(),
      taxCollected: double.tryParse('${json['tax_collected'] ?? 0}') ?? 0,
      onlineTaxCollected: double.tryParse('${json['online_tax_collected'] ?? 0}') ?? 0,
      codTaxCollected: double.tryParse('${json['cod_tax_collected'] ?? 0}') ?? 0,
      amountRemitted: double.tryParse('${json['amount_remitted'] ?? 0}') ?? 0,
      amountPaid: double.tryParse('${json['amount_paid'] ?? 0}') ?? 0,
      status: json['status']?.toString(),
      pendingRemittance: double.tryParse('${json['pending_remittance'] ?? 0}') ?? 0,
      pendingPayment: double.tryParse('${json['pending_payment'] ?? 0}') ?? 0,
      canMarkPaid: json['can_mark_paid'] == true,
      canClear: json['can_clear'] == true,
      logs: logs,
    );
  }
}

class TaxSettlementListModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final TaxSettlementSummaryModel? summary;
  final List<TaxSettlementModel> settlements;

  TaxSettlementListModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.summary,
    required this.settlements,
  });

  factory TaxSettlementListModel.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    final settlements = <TaxSettlementModel>[];
    if (dataRaw is List) {
      for (final item in dataRaw) {
        if (item is Map<String, dynamic>) {
          settlements.add(TaxSettlementModel.fromJson(item));
        }
      }
    }

    return TaxSettlementListModel(
      totalSize: int.tryParse('${json['total_size'] ?? 0}'),
      limit: int.tryParse('${json['limit'] ?? 0}'),
      offset: int.tryParse('${json['offset'] ?? 0}'),
      summary: json['summary'] is Map<String, dynamic>
          ? TaxSettlementSummaryModel.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      settlements: settlements,
    );
  }
}
