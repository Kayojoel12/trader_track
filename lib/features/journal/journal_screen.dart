import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shell/app_shell.dart';
import 'trade.dart';
import 'trade_repository.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final trades = ref.watch(tradesProvider);
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.tr('journal.title'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: context.tr('import.title'),
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: () => context.push('/import'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: context.tr('journal.search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: trades.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (all) {
                    final list = all
                        .where((t) =>
                            _query.isEmpty ||
                            t.symbol.toLowerCase().contains(_query) ||
                            (t.notes ?? '').toLowerCase().contains(_query))
                        .toList();
                    if (list.isEmpty) {
                      return Center(child: Text(context.tr('journal.empty')));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavInset + 70),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _TradeTile(list[i]),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: kNavInset - 4,
            child: FloatingActionButton(
              tooltip: context.tr('trade.new'),
              onPressed: () => context.push('/journal/new'),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeTile extends ConsumerWidget {
  const _TradeTile(this.t);
  final Trade t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (t.status) {
      TradeStatus.win => AppColors.gain,
      TradeStatus.loss => AppColors.loss,
      _ => AppColors.muted,
    };
    final r = t.rMultiple;
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.loss,
        child: const Icon(Icons.delete_outline),
      ),
      // Confirmation avant suppression (exigence du cahier des charges).
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Supprimer ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Non')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Oui')),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => ref.read(tradesProvider.notifier).remove(t.id),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${t.direction == Direction.buy ? context.tr('trade.buy') : context.tr('trade.sell')}'
                      ' · ${t.volume} lot · ${DateFormat.MMMd().add_Hm().format(t.openedAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t.status == TradeStatus.open ? '…' : t.netPnl.toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  if (r != null)
                    Text('${r.toStringAsFixed(1)} R',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
