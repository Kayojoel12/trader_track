import 'package:flutter_test/flutter_test.dart';
import 'package:trade_track/features/journal/trade.dart';
import 'package:trade_track/features/risk/position_sizer.dart';

Trade _t({double gross = 100, double comm = -7, double swap = -1, double? risk = 50, bool closed = true}) {
  final open = DateTime(2026, 10, 29, 9);
  return Trade(
    id: '1', accountId: 'a', symbol: 'EURUSD', direction: Direction.buy,
    volume: 0.5, entryPrice: 1.085, openedAt: open,
    closedAt: closed ? open.add(const Duration(hours: 2)) : null,
    grossPnl: gross, commission: comm, swap: swap, riskAmount: risk,
  );
}

void main() {
  test('net = brut + commission + swap + frais', () => expect(_t().netPnl, 92));
  test('R multiple = net / risque', () => expect(_t().rMultiple, closeTo(1.84, 1e-9)));
  test('R inconnu sans risque', () => expect(_t(risk: null).rMultiple, isNull));
  test('statuts', () {
    expect(_t().status, TradeStatus.win);
    expect(_t(gross: -100).status, TradeStatus.loss);
    expect(_t(gross: 8).status, TradeStatus.breakeven);
    expect(_t(closed: false).status, TradeStatus.open);
  });
  test('durée', () => expect(_t().duration, const Duration(hours: 2)));
  test('lot arrondi vers le bas', () {
    final risk = PositionSizer.riskFromPercent(12480, 1); // 124,80
    final lots = PositionSizer.lotSize(riskAmount: risk, stopPips: 25, pipValuePerLot: 10);
    expect(lots, closeTo(0.49, 1e-9));
  });
}
