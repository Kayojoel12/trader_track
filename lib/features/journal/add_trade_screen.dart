import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'trade.dart';
import 'trade_repository.dart';

class AddTradeScreen extends ConsumerStatefulWidget {
  const AddTradeScreen({super.key});

  @override
  ConsumerState<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends ConsumerState<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();

  Direction _direction = Direction.buy;
  DateTime _openedAt = DateTime.now();
  DateTime? _closedAt;
  bool _isClosed = true;
  int _confidence = 3;

  final _c = <String, TextEditingController>{
    for (final k in [
      'symbol',
      'volume',
      'entry',
      'exit',
      'sl',
      'tp',
      'gross',
      'commission',
      'swap',
      'risk',
      'notes',
    ])
      k: TextEditingController(),
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _c['volume']!.text = '0.10';
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _n(String k) => double.tryParse(_c[k]!.text.replaceAll(',', '.').trim());

  Future<void> _pickDateTime({required bool isOpen}) async {
    final current = isOpen ? _openedAt : (_closedAt ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final chosen = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isOpen) {
        _openedAt = chosen;
      } else {
        _closedAt = chosen;
      }
    });
  }

  Future<void> _save() async {
    final symbol = _c['symbol']!.text.trim().toUpperCase();
    final volume = _n('volume');
    final entry = _n('entry');

    if (symbol.isEmpty || volume == null || volume <= 0 || entry == null || entry <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('trade.errorRequired')),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(tradeRepositoryProvider);
      final accountId = await repo.ensureDefaultAccount();
      final exit = _n('exit');

      final trade = Trade(
        id: const Uuid().v4(),
        accountId: accountId,
        symbol: symbol,
        direction: _direction,
        volume: volume,
        entryPrice: entry,
        exitPrice: _isClosed ? exit : null,
        sl: _n('sl'),
        tp: _n('tp'),
        openedAt: _openedAt,
        closedAt: _isClosed ? (_closedAt ?? _openedAt) : null,
        grossPnl: _isClosed ? (_n('gross') ?? 0) : 0,
        commission: _n('commission') ?? 0,
        swap: _n('swap') ?? 0,
        riskAmount: _n('risk'),
        confidence: _confidence,
        notes: _c['notes']!.text.trim().isEmpty ? null : _c['notes']!.text.trim(),
      );

      await ref.read(tradesProvider.notifier).add(trade);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('trade.savedSuccess')),
            backgroundColor: AppColors.gain,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String key,
    String labelKey, {
    bool isText = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        textCapitalization: isText ? TextCapitalization.characters : TextCapitalization.none,
        keyboardType: isText
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          labelText: context.tr(labelKey) + (isRequired ? ' *' : ''),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('trade.new')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<Direction>(
                    segments: [
                      ButtonSegment(
                        value: Direction.buy,
                        label: Text(context.tr('trade.buy')),
                        icon: const Icon(Icons.arrow_upward, color: AppColors.gain),
                      ),
                      ButtonSegment(
                        value: Direction.sell,
                        label: Text(context.tr('trade.sell')),
                        icon: const Icon(Icons.arrow_downward, color: AppColors.loss),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (s) => setState(() => _direction = s.first),
                  ),
                  const SizedBox(height: 16),
                  _field('symbol', 'trade.symbol', isText: true, isRequired: true),
                  Row(
                    children: [
                      Expanded(child: _field('volume', 'trade.volume', isRequired: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('entry', 'trade.entry', isRequired: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('sl', 'trade.sl')),
                      const SizedBox(width: 12),
                      Expanded(child: _field('tp', 'trade.tp')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field('risk', 'trade.risk')),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Position clôturée ?', style: TextStyle(fontSize: 14)),
                    value: _isClosed,
                    onChanged: (v) => setState(() => _isClosed = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isClosed) ...[
                    Row(
                      children: [
                        Expanded(child: _field('exit', 'trade.exit')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('gross', 'trade.gross')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field('commission', 'trade.commission')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('swap', 'trade.swap')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.calendar_today, size: 20),
                            title: Text(context.tr('trade.dateOpen')),
                            subtitle: Text(df.format(_openedAt)),
                            trailing: const Icon(Icons.edit, size: 18),
                            onTap: () => _pickDateTime(isOpen: true),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          if (_isClosed)
                            ListTile(
                              leading: const Icon(Icons.event_available, size: 20),
                              title: Text(context.tr('trade.dateClose')),
                              subtitle: Text(df.format(_closedAt ?? _openedAt)),
                              trailing: const Icon(Icons.edit, size: 18),
                              onTap: () => _pickDateTime(isOpen: false),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('trade.confidence'),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('$_confidence / 5',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ],
                          ),
                          Slider(
                            value: _confidence.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: '$_confidence',
                            onChanged: (v) => setState(() => _confidence = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _c['notes'],
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr('trade.notes'),
                      hintText: 'Stratégie, contexte de marché, émotions...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(context.tr('common.save')),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
