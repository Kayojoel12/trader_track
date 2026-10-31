import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shell/app_shell.dart';
import '../journal/trade.dart';
import '../journal/trade_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('analytics.title')),
      ),
      body: SafeArea(
        child: tradesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur: $err')),
          data: (trades) {
            if (trades.isEmpty) {
              return Center(
                child: Text(
                  context.tr('journal.empty'),
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }

            final closed = trades.where((t) => t.closedAt != null).toList();
            final wins = closed.where((t) => t.status == TradeStatus.win).toList();
            final losses = closed.where((t) => t.status == TradeStatus.loss).toList();
            final be = closed.where((t) => t.status == TradeStatus.breakeven).toList();
            final open = trades.where((t) => t.closedAt == null).toList();

            final totalNetPnl = closed.fold<double>(0.0, (acc, t) => acc + t.netPnl);
            final grossWins = wins.fold<double>(0.0, (acc, t) => acc + t.netPnl);
            final grossLosses = losses.fold<double>(0.0, (acc, t) => acc + t.netPnl.abs());

            final winRate = closed.isNotEmpty ? (wins.length / closed.length) * 100 : 0.0;
            final profitFactor = grossLosses > 0
                ? (grossWins / grossLosses)
                : (grossWins > 0 ? double.infinity : 0.0);

            final rTrades = closed.where((t) => t.rMultiple != null).map((t) => t.rMultiple!).toList();
            final avgR = rTrades.isNotEmpty
                ? rTrades.reduce((a, b) => a + b) / rTrades.length
                : 0.0;

            Trade? bestTrade;
            Trade? worstTrade;
            for (final t in closed) {
              if (bestTrade == null || t.netPnl > bestTrade.netPnl) bestTrade = t;
              if (worstTrade == null || t.netPnl < worstTrade.netPnl) worstTrade = t;
            }

            // Statistiques par symbole
            final symbolStats = <String, List<Trade>>{};
            for (final t in closed) {
              symbolStats.putIfAbsent(t.symbol, () => []).add(t);
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, kNavInset + 20),
                  children: [
                    _buildPnlCard(context, totalNetPnl, closed.length, open.length),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(context, winRate, profitFactor, avgR, wins.length, losses.length, be.length),
                    const SizedBox(height: 16),
                    if (bestTrade != null || worstTrade != null)
                      _buildExtremesCard(context, bestTrade, worstTrade),
                    const SizedBox(height: 16),
                    _buildSymbolBreakdownCard(context, symbolStats),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPnlCard(BuildContext context, double totalPnl, int closedCount, int openCount) {
    final isGain = totalPnl >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isGain ? AppColors.gain : AppColors.loss).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('analytics.netPnl'),
            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${totalPnl >= 0 ? '+' : ''}${totalPnl.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isGain ? AppColors.gain : AppColors.loss,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text('$closedCount clôturés · $openCount en cours',
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.bg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    double winRate,
    double pf,
    double avgR,
    int wins,
    int losses,
    int be,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _metricTile(
                  context,
                  context.tr('analytics.winrate'),
                  '${winRate.toStringAsFixed(1)}%',
                  winRate >= 50 ? AppColors.gain : AppColors.loss,
                ),
                _metricTile(
                  context,
                  context.tr('analytics.profitFactor'),
                  pf.isInfinite ? '∞' : pf.toStringAsFixed(2),
                  pf >= 1.5 ? AppColors.gain : (pf >= 1.0 ? AppColors.warn : AppColors.loss),
                ),
                _metricTile(
                  context,
                  context.tr('analytics.avgR'),
                  '${avgR.toStringAsFixed(2)} R',
                  avgR >= 1.0 ? AppColors.gain : AppColors.muted,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _countTile(context.tr('analytics.wins'), wins, AppColors.gain),
                _countTile(context.tr('analytics.losses'), losses, AppColors.loss),
                _countTile(context.tr('analytics.breakeven'), be, AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _countTile(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text('$label : ', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildExtremesCard(BuildContext context, Trade? best, Trade? worst) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Records',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (best != null)
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: AppColors.gain, size: 18),
                  const SizedBox(width: 8),
                  Text('${context.tr('analytics.bestTrade')} (${best.symbol})',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('+${best.netPnl.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gain)),
                ],
              ),
            if (worst != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_downward, color: AppColors.loss, size: 18),
                  const SizedBox(width: 8),
                  Text('${context.tr('analytics.worstTrade')} (${worst.symbol})',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('${worst.netPnl.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.loss)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolBreakdownCard(BuildContext context, Map<String, List<Trade>> stats) {
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance par Actif',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('Aucune donnée', style: TextStyle(fontSize: 12, color: AppColors.muted))
            else
              for (final e in entries.take(5)) ...[
                Builder(
                  builder: (_) {
                    final list = e.value;
                    final pnl = list.fold<double>(0.0, (acc, t) => acc + t.netPnl);
                    final wins = list.where((t) => t.status == TradeStatus.win).length;
                    final wr = (wins / list.length) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(e.key,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Text('${list.length} trades · ${wr.toStringAsFixed(0)}% WR',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          const Spacer(),
                          Text(
                            '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)} \$',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: pnl >= 0 ? AppColors.gain : AppColors.loss,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
          ],
        ),
      ),
    );
  }
}
