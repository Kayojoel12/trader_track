enum Direction { buy, sell }

enum TradeStatus { open, win, loss, breakeven }

/// Montants signés comme dans MT5 : commission, swap et frais négatifs = coûts.
/// netPnl = grossPnl + commission + swap + fees
class Trade {
  Trade({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.direction,
    required this.volume,
    required this.entryPrice,
    required this.openedAt,
    this.exitPrice,
    this.sl,
    this.tp,
    this.closedAt,
    this.grossPnl = 0,
    this.commission = 0,
    this.swap = 0,
    this.fees = 0,
    this.riskAmount,
    this.confidence,
    this.notes,
    this.source = 'manual',
    this.externalId,
  });

  final String id;
  final String accountId;
  final String symbol;
  final Direction direction;
  final double volume;
  final double entryPrice;
  final double? exitPrice;
  final double? sl;
  final double? tp;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double grossPnl;
  final double commission;
  final double swap;
  final double fees;
  final double? riskAmount;
  final int? confidence;
  final String? notes;
  final String source;
  final String? externalId;

  double get netPnl => grossPnl + commission + swap + fees;

  Duration? get duration => closedAt?.difference(openedAt);

  /// R multiple = résultat net / risque pris (null si le risque est inconnu).
  double? get rMultiple =>
      (riskAmount != null && riskAmount! > 0) ? netPnl / riskAmount! : null;

  TradeStatus get status {
    if (closedAt == null) return TradeStatus.open;
    if (netPnl > 0) return TradeStatus.win;
    if (netPnl < 0) return TradeStatus.loss;
    return TradeStatus.breakeven;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'symbol': symbol,
        'direction': direction.name,
        'volume': volume,
        'entry_price': entryPrice,
        'exit_price': exitPrice,
        'sl': sl,
        'tp': tp,
        'opened_at': openedAt.toUtc().toIso8601String(),
        'closed_at': closedAt?.toUtc().toIso8601String(),
        'gross_pnl': grossPnl,
        'commission': commission,
        'swap': swap,
        'fees': fees,
        'risk_amount': riskAmount,
        'confidence': confidence,
        'notes_md': notes,
        'source': source,
        'external_id': externalId,
      };

  factory Trade.fromJson(Map<String, dynamic> j) {
    double? n(String k) => (j[k] as num?)?.toDouble();
    return Trade(
      id: j['id'] as String,
      accountId: j['account_id'] as String,
      symbol: j['symbol'] as String,
      direction: Direction.values.byName(j['direction'] as String),
      volume: n('volume') ?? 0,
      entryPrice: n('entry_price') ?? 0,
      exitPrice: n('exit_price'),
      sl: n('sl'),
      tp: n('tp'),
      openedAt: DateTime.parse(j['opened_at'] as String).toLocal(),
      closedAt: j['closed_at'] == null ? null : DateTime.parse(j['closed_at'] as String).toLocal(),
      grossPnl: n('gross_pnl') ?? 0,
      commission: n('commission') ?? 0,
      swap: n('swap') ?? 0,
      fees: n('fees') ?? 0,
      riskAmount: n('risk_amount'),
      confidence: j['confidence'] as int?,
      notes: j['notes_md'] as String?,
      source: (j['source'] as String?) ?? 'manual',
      externalId: j['external_id'] as String?,
    );
  }
}
