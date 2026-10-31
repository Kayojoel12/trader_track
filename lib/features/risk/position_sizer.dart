import 'dart:math' as math;

/// Calcul du lot selon le risque et le stop-loss.
/// pipValuePerLot : valeur d'un pip pour 1 lot, dans la devise du compte
/// (ex. 10 pour EURUSD sur un compte en USD).
class PositionSizer {
  static double riskFromPercent(double balance, double percent) => balance * percent / 100;

  /// Lot arrondi vers le BAS au pas du broker : on ne dépasse jamais le risque voulu.
  static double lotSize({
    required double riskAmount,
    required double stopPips,
    required double pipValuePerLot,
    double step = 0.01,
  }) {
    if (riskAmount <= 0 || stopPips <= 0 || pipValuePerLot <= 0) {
      throw ArgumentError('riskAmount, stopPips et pipValuePerLot doivent être > 0');
    }
    final raw = riskAmount / (stopPips * pipValuePerLot);
    return (raw / step).floor() * step;
  }

  static double rr({required double entry, required double sl, required double tp}) =>
      (tp - entry).abs() / math.max((entry - sl).abs(), 1e-12);
}
