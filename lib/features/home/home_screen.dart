import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shell/app_shell.dart';
import '../journal/trade.dart';
import '../journal/trade_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, kNavInset + 20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRADE Track',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          DateFormat.yMMMMEEEEd().format(DateTime.now()),
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      tooltip: context.tr('import.title'),
                      onPressed: () => context.push('/import'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                tradesAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => Text('Erreur: $e'),
                  data: (trades) {
                    final closed = trades.where((t) => t.closedAt != null).toList();
                    final wins = closed.where((t) => t.status == TradeStatus.win).length;
                    final totalPnl = closed.fold<double>(0.0, (acc, t) => acc + t.netPnl);
                    final winRate = closed.isNotEmpty ? (wins / closed.length) * 100 : 0.0;
                    final isGain = totalPnl >= 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('home.summary'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${totalPnl >= 0 ? '+' : ''}${totalPnl.toStringAsFixed(2)} \$',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: isGain ? AppColors.gain : AppColors.loss,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr('analytics.netPnl'),
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${winRate.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: winRate >= 50 ? AppColors.gain : AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr('analytics.winrate'),
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.tr('home.quickActions'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.add,
                                label: context.tr('trade.new'),
                                color: AppColors.accent,
                                onTap: () => context.push('/journal/new'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.calculate_outlined,
                                label: context.tr('risk.calculator'),
                                color: AppColors.warn,
                                onTap: () => context.go('/risk'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.file_upload_outlined,
                                label: context.tr('import.title'),
                                color: AppColors.gain,
                                onTap: () => context.push('/import'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('home.recentTrades'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            TextButton(
                              onPressed: () => context.go('/journal'),
                              child: Text(context.tr('home.allTrades')),
                            ),
                          ],
                        ),
                        if (trades.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  context.tr('journal.empty'),
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ),
                            ),
                          )
                        else
                          for (final t in trades.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MiniTradeCard(t),
                            ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTradeCard extends StatelessWidget {
  const _MiniTradeCard(this.t);
  final Trade t;

  @override
  Widget build(BuildContext context) {
    final color = switch (t.status) {
      TradeStatus.win => AppColors.gain,
      TradeStatus.loss => AppColors.loss,
      _ => AppColors.muted,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${t.direction == Direction.buy ? context.tr('trade.buy') : context.tr('trade.sell')} · ${t.volume} lot',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.closedAt == null ? '…' : '${t.netPnl >= 0 ? '+' : ''}${t.netPnl.toStringAsFixed(2)} \$',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                if (t.rMultiple != null)
                  Text('${t.rMultiple!.toStringAsFixed(1)} R',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
